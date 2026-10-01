<!-- What changed and why, written for a consumer of the kit: what to call instead, what looks different. -->

## Checklist

The five steps from CONTRIBUTING.md, "Pull requests":

- [ ] Branched from `main`; the change is focused, with tests added or updated next to the code (`Tests/<Target>Tests/<same folder>`).
- [ ] `make check` and `make test` pass locally; `make build-catalyst` too when the change touches layout, gestures, or a Mac idiom branch.
- [ ] CHANGELOG entry under `[Unreleased]` in the section that fits (Added, Changed, Fixed, Removed), written for a consumer.
- [ ] Every new public symbol has a DocC comment; a public rename or removal follows the migration policy in CONTRIBUTING.md (step 4).
- [ ] The squash-merge message names the theme of the change.
