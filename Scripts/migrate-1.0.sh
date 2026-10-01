#!/bin/bash
#
# migrate-1.0.sh — rewrite a LumiKit 0.x consumer for LumiKit 1.0.
#
#   Scripts/migrate-1.0.sh <consumer-dir> [--dry-run] [--no-members] [--docs] [--force] [--allow-dirty] [--print-table]
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
# prints a report of the hand edits that remain. `--docs` also rewrites *.md. `--dry-run` runs the
# same passes over a temporary mirror of the files and prints the same counts and report, without
# touching the consumer. The run is not idempotent (LMKTheme is both an old and a new name), so a
# marker file guards against a second pass; `--force` overrides it. A consumer with uncommitted
# changes is refused unless `--allow-dirty` is given (nothing else can undo the rewrite), and the
# LumiKit checkout this script lives in is refused unless `--passes` is given. `--print-table`
# renders the rules as Markdown for docs/MIGRATION-1.0.md and exits.
#
# Exit status: 0 when no `remove:` recipe still matches, 2 while removed API remains, 1 on usage errors.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PKG_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
RULES="$SCRIPT_DIR/migrate-1.0.rules"
MARKER=".lumikit-1.0-migrated"

usage() { sed -n '3,/^set -e/{/^set -e/!p;}' "$0"; exit "${1:-1}"; }

CONSUMER=""; DRY_RUN=0; NO_MEMBERS=0; DOCS=0; FORCE=0; ALLOW_DIRTY=0; PRINT_TABLE=0
PASSES="product,path,type,regex,member,filematch"; PASSES_GIVEN=0; SKIP=""; DECLARATIONS=0; POST_TYPE=0
EXPECT=""
for arg in "$@"; do
    if [ -n "$EXPECT" ]; then
        case "$EXPECT" in passes) PASSES="$arg" ;; skip) SKIP="$arg" ;; esac
        EXPECT=""; continue
    fi
    case "$arg" in
        --passes) EXPECT=passes; PASSES_GIVEN=1 ;;
        --skip) EXPECT=skip ;;
        --declarations) DECLARATIONS=1 ;;
        --post-type) POST_TYPE=1 ;;
        --dry-run) DRY_RUN=1 ;;
        --no-members) NO_MEMBERS=1 ;;
        --docs) DOCS=1 ;;
        --force) FORCE=1 ;;
        --allow-dirty) ALLOW_DIRTY=1 ;;
        --print-table) PRINT_TABLE=1 ;;
        -h|--help) usage 0 ;;
        -*) echo "unknown option: $arg" >&2; usage 1 ;;
        *) CONSUMER="$arg" ;;
    esac
done
[ -z "$EXPECT" ] || { echo "missing value for --$EXPECT" >&2; usage 1; }

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

[ -n "$CONSUMER" ] || usage 1
[ -d "$CONSUMER" ] || { echo "not a directory: $CONSUMER" >&2; exit 1; }
CONSUMER="$(cd "$CONSUMER" && pwd -P)"

# The package's own tree is migrated in stages with --passes; without it, the type pass would turn
# every 1.0 `LMKTheme` in Sources/Tests/Example into `LMKColorTheme`.
case "$CONSUMER/" in
    "$PKG_ROOT/"|"$PKG_ROOT/Sources/"*|"$PKG_ROOT/Tests/"*|"$PKG_ROOT/Example/"*)
        if [ "$PASSES_GIVEN" != 1 ]; then
            echo "error: $CONSUMER is the LumiKit package itself; a consumer lives elsewhere (package-internal runs pass --passes)." >&2
            exit 1
        fi ;;
esac

if [ -f "$CONSUMER/$MARKER" ] && [ "$FORCE" != 1 ]; then
    if [ "$DRY_RUN" = 1 ]; then
        echo "note: $CONSUMER is already migrated ($MARKER present); the dry run rewrites migrated code, so its counts mean nothing." >&2
    else
        echo "error: $CONSUMER already migrated ($MARKER present); a second pass would corrupt the LMKTheme swap. Use --force to override." >&2
        exit 1
    fi
fi

# The rewrite is only reversible through version control, so a dirty tree is refused.
if [ "$DRY_RUN" != 1 ] && [ "$ALLOW_DIRTY" != 1 ]; then
    if git -C "$CONSUMER" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        if [ -n "$(git -C "$CONSUMER" status --porcelain -- . ":(exclude)$MARKER")" ]; then
            echo "error: $CONSUMER has uncommitted changes; commit or stash them first so the rewrite can be reverted, or pass --allow-dirty." >&2
            exit 1
        fi
    else
        echo "note: $CONSUMER is not a git work tree; keep a copy, the rewrite cannot be undone." >&2
    fi
fi

cd "$CONSUMER"

# Files in scope, relative to the consumer (excluding build products, dependency checkouts, and a
# LumiKit checkout vendored inside the consumer, whose 1.0 sources must not be rewritten).
PKG_PRUNE=()
case "$PKG_ROOT/" in
    "$CONSUMER/"?*)
        PKG_REL="./${PKG_ROOT#"$CONSUMER"/}"
        PKG_PRUNE=(-o -path "$(printf '%s' "$PKG_REL" | sed 's/[][*?\\]/\\&/g')") ;;
esac
find_files() {
    find . \( -path '*/.build' -o -path '*/DerivedData' -o -path '*/build' -o -path '*/Pods' -o -path '*/.git' -o -path '*/node_modules' \
        ${PKG_PRUNE[@]+"${PKG_PRUNE[@]}"} \) -prune -o -type f "$@" -print0
}
SWIFT_FILES=$(find_files -name '*.swift' | tr '\0' '\n' | LC_ALL=C sort)
PRODUCT_FILES=$(find_files \( -name 'project.pbxproj' -o -name 'Package.swift' -o -name 'project.yml' -o -name '*.swift' \) | tr '\0' '\n')
DOC_FILES=""
[ "$DOCS" = 1 ] && DOC_FILES=$(find_files -name '*.md' | tr '\0' '\n')
ALL_FILES=$(printf '%s\n%s\n' "$PRODUCT_FILES" "$DOC_FILES" | sed '/^$/d' | LC_ALL=C sort -u)

[ -n "$SWIFT_FILES" ] || { echo "no Swift files under $CONSUMER" >&2; exit 1; }

echo "LumiKit 1.0 migration: $CONSUMER"
echo "  files: $(echo "$SWIFT_FILES" | wc -l | tr -d ' ') swift$( [ "$DOCS" = 1 ] && echo ", $(echo "$DOC_FILES" | sed '/^$/d' | wc -l | tr -d ' ') markdown" )"

# A dry run rewrites into a temporary mirror of the files in scope and runs the import and report
# passes there, so it prints exactly what the real run would; the mirror goes away on exit.
WORK="$CONSUMER"
MIRROR=""
if [ "$DRY_RUN" = 1 ]; then
    echo "  mode: dry run (no files written)"
    MIRROR="$(mktemp -d "${TMPDIR:-/tmp}/lumikit-migrate.XXXXXX")"
    trap 'rm -rf "${MIRROR:?}"' EXIT
    trap 'exit 130' INT TERM
    WORK="$MIRROR"
fi

# One perl process does all rewriting passes so the rules file is parsed once and the type pass is a
# single simultaneous substitution. Every file is rewritten in memory first; only then are the marker
# and the files written, so a bad rule aborts before anything on disk changes and a rewritten tree
# always carries its marker. In a dry run every file in scope is written to the mirror instead.
MARKER_TEXT="$(shasum -a 256 "$RULES" | awk '{print $1}')"
export LMK_RULES="$RULES" LMK_DRY_RUN="$DRY_RUN" LMK_NO_MEMBERS="$NO_MEMBERS" LMK_PASSES="$PASSES" LMK_SKIP="$SKIP" \
    LMK_DECLARATIONS="$DECLARATIONS" LMK_POST_TYPE="$POST_TYPE" LMK_OUT_ROOT="$MIRROR" LMK_MARKER="$CONSUMER/$MARKER" LMK_MARKER_TEXT="$MARKER_TEXT"
printf '%s\n' "$ALL_FILES" | perl -e '
    use strict; use warnings;
    use File::Basename qw(dirname);
    use File::Path qw(make_path);
    eval {
        my (@product, @path, %type, @regex, @member, @filematch, %all_types);
        open my $rf, "<", $ENV{LMK_RULES} or die "rules: $!\n";
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
        my $out_root = $ENV{LMK_OUT_ROOT};
        my $no_members = $ENV{LMK_NO_MEMBERS} eq "1";
        my $declarations = $ENV{LMK_DECLARATIONS} eq "1";
        my ($files_changed, $total) = (0, 0);
        my (%counts, @pending);
        my $bump = sub { my ($rule, $n) = @_; $counts{$rule} += $n; $total += $n };
        my $write = sub {
            my ($file, $text) = @_;
            open my $wh, ">", $file or die "$file: $!\n"; print $wh $text; close $wh or die "$file: $!\n";
        };

        while (my $file = <STDIN>) {
            chomp $file; next unless length $file && -f $file;
            open my $fh, "<", $file or die "$file: $!\n";
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
            $files_changed++ if $out ne $src;
            if (length $out_root) {
                my $dest = "$out_root/$file";
                make_path(dirname($dest));
                $write->($dest, $out);
            } elsif ($out ne $src) {
                push @pending, [$file, $out];
            }
        }
        unless (length $out_root) {
            $write->($ENV{LMK_MARKER}, "$ENV{LMK_MARKER_TEXT}\n");
            $write->(@$_) for @pending;
        }
        my $verb = $ENV{LMK_DRY_RUN} eq "1" ? "would rewrite" : "rewritten";
        print "  $verb: $files_changed file(s), $total substitution(s)\n";
        for my $rule (sort { $counts{$b} <=> $counts{$a} || $a cmp $b } keys %counts) { printf "    %6d  %s\n", $counts{$rule}, $rule }
        1;
    } or do { print STDERR "error: $@"; exit 1 };
'

cd "$WORK"

# Import insertion for the new products (Photo / Debug), on Swift files only.
insert_import() { # module, symbol-regex
    local module="$1" symbols="$2" f
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        case "$f" in */Sources/"$module"/*) continue ;; esac   # the module's own files (package-internal runs)
        grep -qE "$symbols" "$f" || continue
        grep -qE "^[[:space:]]*(@testable )?import $module\b" "$f" && continue
        if grep -qE '^[[:space:]]*import LumiKitUI\b' "$f"; then
            perl -0pi -e "s/^(\s*import LumiKitUI\b[^\n]*\n)/\$1import $module\n/m" "$f"
            if [ "$DRY_RUN" = 1 ]; then echo "  would add: import $module  ${f#./}"; else echo "  added: import $module  ${f#./}"; fi
        else
            echo "  needs: import $module (no LumiKitUI import to anchor on)  ${f#./}"
        fi
    done <<< "$SWIFT_FILES"
}
echo "imports:"
insert_import LumiKitPhoto '\bLMK(Photo\w+|SinglePhotoViewer|CropAspectRatio|SharePreview\w*)\b'
insert_import LumiKitDebug '\bLMKNetwork\w+\b|lmk_enableNetworkLogging'

# Report pass: every hand edit, by file:line. One perl process reads each file once and runs every
# report pattern over it (a pattern that does not compile aborts the run instead of vanishing).
echo "report:"
REPORT_STATUS=0
printf '%s\n' "$SWIFT_FILES" | perl -e '
    use strict; use warnings;
    my @rules;
    eval {
        open my $rf, "<", $ENV{LMK_RULES} or die "rules: $!\n";
        while (<$rf>) {
            chomp; next if /^\s*(#|$)/;
            my ($kind, $pattern, $recipe) = split /\t/, $_, 3;
            next unless $kind eq "report";
            die "report rule without a recipe: $pattern\n" unless defined $recipe && length $recipe;
            my $re = eval { qr/$pattern/ } or die "report rule does not compile: $pattern\n$@";
            push @rules, [$re, $recipe, []];
        }
        while (my $file = <STDIN>) {
            chomp $file; next unless length $file && -f $file;
            open my $fh, "<", $file or die "$file: $!\n";
            local $/; my $src = <$fh>; close $fh;
            (my $shown = $file) =~ s{^\./}{};
            for my $r (@rules) {
                while ($src =~ /$r->[0]/g) {
                    my $line = 1 + (substr($src, 0, pos($src)) =~ tr/\n//);
                    push @{$r->[2]}, "$shown:$line";
                }
            }
        }
        1;
    } or do { print STDERR "error: $@"; exit 1 };
    my $remove_hits = 0;
    for my $r (@rules) {
        my ($re, $recipe, $hits) = @$r;
        next unless @$hits;
        $remove_hits += @$hits if $recipe =~ /^remove:/;
        print "  - $recipe\n";
        print "      $_\n" for @$hits;
    }
    if ($remove_hits > 0) {
        print "done: $remove_hits site(s) still use removed API (see \x27remove:\x27 recipes above).\n";
        exit 2;
    }
    print "done.\n";
' || REPORT_STATUS=$?
exit "$REPORT_STATUS"
