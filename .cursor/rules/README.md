# Cursor Rules for LumiKit

**Rules** = enforceable, actionable (what to do/avoid). **Context** = orientation, navigation. See [.claude/CLAUDE.md](../../.claude/CLAUDE.md) for package overview, targets, and build commands.

Applied by: **Always Apply**, **globs**, or **@-mention**. Precedence: Team > Project > User.

---

## Rules Index

| Rule | Apply | Summary |
|------|-------|---------|
| `naming.RULE.md` | Always | LMK prefix, lmk_ extensions, file naming |
| `target-separation.RULE.md` | Always | Core (Foundation) vs UI (UIKit+SnapKit) vs Lottie boundaries |
| `swift6-concurrency.RULE.md` | Always | @MainActor, Sendable, nonisolated(unsafe), configurable strings |
| `design-tokens.RULE.md` | Always | LMKColor, LMKSpacing, LMKTypography — never hardcode values |
| `testing.RULE.md` | Test files | AAA pattern, xcodebuild test, @MainActor, naming |

---

Refs: [CLAUDE.md](../../.claude/CLAUDE.md), [Package.swift](../../Package.swift).
