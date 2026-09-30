#!/bin/bash
#
# migrate-1.0.sh — rewrite a LumiKit 0.x consumer for LumiKit 1.0.
#
#   Scripts/migrate-1.0.sh <consumer-dir> [--dry-run] [--no-members] [--docs] [--force] [--print-table]
#                          [--passes product,path,type,regex,member,filematch] [--skip <perl-regex>] [--declarations] [--post-type]
#
# `--passes` restricts the rewriting passes (LumiKit itself is migrated in stages), `--skip` drops every
# rule whose OLD side matches the regex, and `--declarations` also renames `var/let/func` declarations for
# member rules; `--post-type` rewrites the OLD side of every path rule through the type map first, for a
# tree whose type identifiers were already renamed (package-internal use; a consumer never declares
# LumiKit's members and always runs the passes in order).
#
# Applies Scripts/migrate-1.0.rules (see the header there for the pass order) to every .swift file
# plus project.pbxproj / Package.swift / project.yml (product names) under <consumer-dir>, then
# prints a report of the hand edits that remain. `--docs` also rewrites *.md. `--dry-run` reports
# without writing. The run is not idempotent (LMKTheme is both an old and a new name), so a marker
# file guards against a second pass; `--force` overrides it. `--print-table` renders the rules as
# Markdown for docs/MIGRATION-1.0.md and exits.
#
# Exit status: 0 when no `remove:` recipe still matches, 2 while removed API remains, 1 on usage errors.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES="$SCRIPT_DIR/migrate-1.0.rules"
MARKER=".lumikit-1.0-migrated"

usage() { sed -n '3,15p' "$0"; exit 1; }

CONSUMER=""; DRY_RUN=0; NO_MEMBERS=0; DOCS=0; FORCE=0; PRINT_TABLE=0
PASSES="product,path,type,regex,member,filematch"; SKIP=""; DECLARATIONS=0; POST_TYPE=0
EXPECT=""
for arg in "$@"; do
    if [ -n "$EXPECT" ]; then
        case "$EXPECT" in passes) PASSES="$arg" ;; skip) SKIP="$arg" ;; esac
        EXPECT=""; continue
    fi
    case "$arg" in
        --passes) EXPECT=passes ;;
        --skip) EXPECT=skip ;;
        --declarations) DECLARATIONS=1 ;;
        --post-type) POST_TYPE=1 ;;
        --dry-run) DRY_RUN=1 ;;
        --no-members) NO_MEMBERS=1 ;;
        --docs) DOCS=1 ;;
        --force) FORCE=1 ;;
        --print-table) PRINT_TABLE=1 ;;
        -h|--help) usage ;;
        -*) echo "unknown option: $arg" >&2; usage ;;
        *) CONSUMER="$arg" ;;
    esac
done

[ -f "$RULES" ] || { echo "rules file missing: $RULES" >&2; exit 1; }

# Renders the rules grouped by pass. The NEW side of a path / regex / member rule is shown after the
# type pass (what the consumer ends up with), since a path rule is written against the OLD type name.
if [ "$PRINT_TABLE" = 1 ]; then
    perl -e '
        use strict; use warnings;
        my (%by_kind, %types);
        open my $rf, "<", $ARGV[0] or die "rules: $!";
        while (<$rf>) {
            chomp; next if /^\s*(#|$)/;
            my ($kind, $old, $new, $note) = split /\t/, $_, 4;
            push @{$by_kind{$kind}}, [$old, $new, $note // ""];
            $types{$old} = $new if $kind eq "type";
        }
        my $alt = join "|", map { quotemeta } sort { length($b) <=> length($a) } keys %types;
        my $cell = sub { my $s = shift; $s =~ s/\|/\\|/g; $s };
        my %title = (
            product => ["Products", "Old", "New"],
            path => ["Dotted paths", "Old", "New"],
            type => ["Types", "Old", "New"],
            regex => ["Call shapes (Perl regex, applied after the type pass)", "Pattern", "Replacement"],
            member => ["Members (type-blind)", "Old", "New"],
            filematch => ["File-conditional (only in files matching the precondition)", "Precondition", "Pattern and replacement"],
            report => ["Hand edits (reported by file and line, never rewritten)", "Pattern", "Recipe"],
        );
        for my $kind (qw(product path type regex member filematch report)) {
            next unless $by_kind{$kind};
            my ($heading, $left, $right) = @{$title{$kind}};
            print "\n### $heading\n\n| $left | $right |\n|---|---|\n";
            for my $r (@{$by_kind{$kind}}) {
                my ($old, $new, $note) = @$r;
                if ($kind eq "path" || $kind eq "member") { $new =~ s/\b(?:$alt)\b/$types{$&}/g if $alt }
                if ($kind eq "report") { printf "| `%s` | %s |\n", $cell->($old), $cell->($new); next }
                if ($kind eq "filematch") { printf "| `%s` | `%s` to `%s` |\n", $cell->($old), $cell->($new), $cell->($note); next }
                printf "| `%s` | `%s` |\n", $cell->($old), $cell->($new);
            }
        }
    ' "$RULES"
    exit 0
fi

[ -n "$CONSUMER" ] || usage
[ -d "$CONSUMER" ] || { echo "not a directory: $CONSUMER" >&2; exit 1; }
CONSUMER="$(cd "$CONSUMER" && pwd)"

if [ -f "$CONSUMER/$MARKER" ] && [ "$FORCE" != 1 ] && [ "$DRY_RUN" != 1 ]; then
    echo "error: $CONSUMER already migrated ($MARKER present); a second pass would corrupt the LMKTheme swap. Use --force to override." >&2
    exit 1
fi

# Files in scope (excluding build products and dependency checkouts).
find_files() {
    find "$CONSUMER" \( -path '*/.build' -o -path '*/DerivedData' -o -path '*/build' -o -path '*/Pods' -o -path '*/.git' -o -path '*/node_modules' \) -prune -o -type f "$@" -print0
}
SWIFT_FILES=$(find_files -name '*.swift' | tr '\0' '\n')
PRODUCT_FILES=$(find_files \( -name 'project.pbxproj' -o -name 'Package.swift' -o -name 'project.yml' -o -name '*.swift' \) | tr '\0' '\n')
DOC_FILES=""
[ "$DOCS" = 1 ] && DOC_FILES=$(find_files -name '*.md' | tr '\0' '\n')
ALL_FILES=$(printf '%s\n%s\n' "$PRODUCT_FILES" "$DOC_FILES" | sort -u | sed '/^$/d')

[ -n "$SWIFT_FILES" ] || { echo "no Swift files under $CONSUMER" >&2; exit 1; }

echo "LumiKit 1.0 migration: $CONSUMER"
echo "  files: $(echo "$SWIFT_FILES" | wc -l | tr -d ' ') swift$( [ "$DOCS" = 1 ] && echo ", $(echo "$DOC_FILES" | sed '/^$/d' | wc -l | tr -d ' ') markdown" )"
[ "$DRY_RUN" = 1 ] && echo "  mode: dry run (no files written)"

# One perl process does all rewriting passes so the rules file is parsed once and the type pass is
# a single simultaneous substitution. In dry-run mode it only counts would-be changes.
export LMK_RULES="$RULES" LMK_DRY_RUN="$DRY_RUN" LMK_NO_MEMBERS="$NO_MEMBERS" LMK_PASSES="$PASSES" LMK_SKIP="$SKIP" LMK_DECLARATIONS="$DECLARATIONS" LMK_POST_TYPE="$POST_TYPE"
echo "$ALL_FILES" | perl -e '
    use strict; use warnings;
    my (@product, @path, %type, @regex, @member, @filematch, %all_types);
    open my $rf, "<", $ENV{LMK_RULES} or die "rules: $!";
    while (<$rf>) {
        chomp; next if /^\s*(#|$)/;
        my ($kind, $old, $new, $note) = split /\t/, $_, 4;
        die "bad rule line: $_\n" unless defined $new;
        if ($kind eq "type") { $all_types{$old} = $new }   # the post-type map sees every type rule, skipped or not
        next if length $ENV{LMK_SKIP} && $old =~ /$ENV{LMK_SKIP}/;
        next if $kind ne "report" && index(",$ENV{LMK_PASSES},", ",$kind,") < 0;
        if    ($kind eq "product")   { push @product, [$old, $new] }
        elsif ($kind eq "path")      { push @path, [$old, $new] }
        elsif ($kind eq "type")      { $type{$old} = $new }
        elsif ($kind eq "regex")     { push @regex, [$old, $new] }
        elsif ($kind eq "member")    { push @member, [$old, $new] }
        elsif ($kind eq "filematch") { push @filematch, [$old, $new, $note] }
        elsif ($kind eq "report")    { }
        else { die "unknown rule kind: $kind\n" }
    }
    if ($ENV{LMK_POST_TYPE} eq "1" && %all_types) {
        my $alt = join "|", map { quotemeta } sort { length($b) <=> length($a) } keys %all_types;
        for my $r (@path) { $r->[0] =~ s/\b(?:$alt)\b/$all_types{$&}/g; $r->[1] =~ s/\b(?:$alt)\b/$all_types{$&}/g }
    }
    # Longest-first everywhere so a shorter rule never eats the prefix of a longer one.
    @path = sort { length($b->[0]) <=> length($a->[0]) } @path;
    my $type_alt = join "|", map { quotemeta } sort { length($b) <=> length($a) } keys %type;
    my $type_re = qr/\b(?:$type_alt)\b/;
    my $dry = $ENV{LMK_DRY_RUN} eq "1";
    my $no_members = $ENV{LMK_NO_MEMBERS} eq "1";
    my $declarations = $ENV{LMK_DECLARATIONS} eq "1";
    my ($files_changed, $total) = (0, 0);
    my %counts;
    my $bump = sub { my ($rule, $n) = @_; $counts{$rule} += $n; $total += $n };

    while (my $file = <STDIN>) {
        chomp $file; next unless length $file && -f $file;
        open my $fh, "<", $file or die "$file: $!";
        local $/; my $src = <$fh>; close $fh;
        my $out = $src;
        my $is_swift = $file =~ /\.swift$/;
        my $is_doc = $file =~ /\.md$/;

        for my $r (@product) { my $n = ($out =~ s/\b\Q$r->[0]\E\b/$r->[1]/g); $bump->("product $r->[0]", $n) if $n }
        if ($is_swift || $is_doc) {
            for my $r (@path) {
                my $tail = ($r->[0] =~ /\w$/) ? "\\b" : "";   # a literal ending in a word char must not match a longer member
                my $n = ($out =~ s/(?<![\w.])\Q$r->[0]\E$tail/$r->[1]/g); $bump->("path $r->[0]", $n) if $n;
            }
            if (%type) { my $n = ($out =~ s/$type_re/$type{$&}/g); $bump->("type pass", $n) if $n }
            for my $r (@regex) { my $n = eval "\$out =~ s/$r->[0]/$r->[1]/g"; die "regex rule $r->[0]: $@" if $@; $bump->("regex $r->[0]", $n) if $n }
            unless ($no_members) {
                for my $r (@member) {
                    my ($o, $nw) = @$r;
                    my $n;
                    if ($o =~ /^\[/) { $n = ($out =~ s/\Q$o\E/$nw/g) }
                    else {
                        my $tail = ($o =~ /[()]$/) ? "" : "\\b";
                        $n = ($out =~ s/\.\Q$o\E$tail/.$nw/g);
                        if ($declarations) {
                            (my $bare = $o) =~ s/[()]+$//; (my $bare_new = $nw) =~ s/[()]+$//;
                            $n += ($out =~ s/\b((?:var|let|func)\s+)\Q$bare\E\b/$1$bare_new/g);
                        }
                    }
                    $bump->("member $o", $n) if $n;
                }
            }
            for my $r (@filematch) {
                next unless $out =~ /\Q$r->[0]\E/;
                my $n = eval "\$out =~ s/$r->[1]/$r->[2]/g"; die "filematch rule $r->[1]: $@" if $@;
                $bump->("filematch $r->[1]", $n) if $n;
            }
        }
        if ($out ne $src) {
            $files_changed++;
            unless ($dry) { open my $wh, ">", $file or die "$file: $!"; print $wh $out; close $wh }
        }
    }
    print "  rewritten: $files_changed file(s), $total substitution(s)\n";
    for my $rule (sort { $counts{$b} <=> $counts{$a} } keys %counts) { printf "    %6d  %s\n", $counts{$rule}, $rule }
'

# Import insertion for the new products (Photo / Debug), on Swift files only.
insert_import() { # module, symbol-regex
    local module="$1" symbols="$2"
    echo "$SWIFT_FILES" | while IFS= read -r f; do
        [ -n "$f" ] || continue
        case "$f" in */Sources/"$module"/*) continue ;; esac   # the module's own files (package-internal runs)
        grep -qE "$symbols" "$f" || continue
        grep -qE "^\s*(@testable )?import $module\b" "$f" && continue
        if [ "$DRY_RUN" = 1 ]; then
            echo "  needs: import $module  ${f#"$CONSUMER"/}"
        elif grep -qE '^\s*import LumiKitUI\b' "$f"; then
            perl -0pi -e "s/^(\s*import LumiKitUI\b[^\n]*\n)/\$1import $module\n/m" "$f"
            echo "  added: import $module  ${f#"$CONSUMER"/}"
        else
            echo "  needs: import $module (no LumiKitUI import to anchor on)  ${f#"$CONSUMER"/}"
        fi
    done
}
echo "imports:"
insert_import LumiKitPhoto '\bLMK(Photo\w+|SinglePhotoViewer|CropAspectRatio|SharePreview\w*)\b'
insert_import LumiKitDebug '\bLMKNetwork\w+\b|lmk_enableNetworkLogging'

# Report pass: every hand edit, by file:line.
echo "report:"
REMOVE_HITS=0
while IFS=$'\t' read -r kind pattern recipe; do
    [ "$kind" = "report" ] || continue
    hits=$(echo "$SWIFT_FILES" | xargs -I{} perl -0ne "while (/$pattern/g) { my \$line = 1 + (substr(\$_, 0, pos()) =~ tr/\n//); print \"\$ARGV:\$line\n\" }" {} 2>/dev/null || true)
    [ -n "$hits" ] || continue
    if [[ "$recipe" == remove:* ]]; then REMOVE_HITS=$((REMOVE_HITS + $(echo "$hits" | wc -l))); fi
    echo "  - $recipe"
    echo "$hits" | sed "s#^$CONSUMER/#      #"
done < <(grep -E '^report' "$RULES")

if [ "$DRY_RUN" != 1 ]; then
    shasum -a 256 "$RULES" | awk '{print $1}' > "$CONSUMER/$MARKER"
fi

if [ "$REMOVE_HITS" -gt 0 ]; then
    echo "done: $REMOVE_HITS site(s) still use removed API (see 'remove:' recipes above)."
    exit 2
fi
echo "done."
