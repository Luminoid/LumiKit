# Cursor Rules for LumiKit

**Rules** = enforceable, actionable (what to do/avoid). **Context** = orientation, navigation. See [.claude/CLAUDE.md](../../.claude/CLAUDE.md) for the package overview, products, and build commands, and [CONTRIBUTING.md](../../CONTRIBUTING.md) for the full naming spec.

Applied by: **Always Apply**, **globs**, or **@-mention**. Precedence: Team > Project > User.

---

## Rules Index

| Rule | Apply | Summary |
|------|-------|---------|
| `naming.RULE.md` | Always | LMK prefix, subject-noun namespaces, ViewController suffix, on<Event> callbacks, present(from:) / show(in:), lmk_ extensions, nested Strings and Style |
| `target-separation.RULE.md` | Always | Core (Foundation) / UI (UIKit+SnapKit) / Photo (PhotosUI) / Debug (DEBUG-only) / Lottie boundaries |
| `swift6-concurrency.RULE.md` | Always | MainActor default isolation, nonisolated Sendable value types, Mutex in Core, owned Tasks |
| `design-tokens.RULE.md` | Always | Tokens, the LMKTheme value, the Style pattern, no hard-coded values, no theme reads in components |
| `testing.RULE.md` | Test files | Swift Testing, @MainActor, LMKThemeTesting, make targets, xctest-host gotchas |

---

Refs: [CLAUDE.md](../../.claude/CLAUDE.md), [CONTRIBUTING.md](../../CONTRIBUTING.md), [Package.swift](../../Package.swift).
