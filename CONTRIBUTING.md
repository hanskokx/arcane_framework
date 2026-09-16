Contributing
============

[Improvements, bug reports, feature requests welcome][gh-issues].

- Please include `dart --version` and the package version when reporting bugs.
- Code should be formatted with `dartfmt`.
- Public methods should have doc comments and test coverage.
- Follow TDD for all framework changes: write or update tests first, then implement.
- Coverage is enforced in CI at 100% line coverage for `lib/src/**` and `lib/arcane_framework.dart`.
- Use `flutter test --coverage` and then `bash tool/check_coverage.sh` locally to validate the same coverage gate used by CI.
- Itemize user-facing changes in the `HEAD` section of the `CHANGELOG` file.
- Use [well-formatted commit messages][git-log-fmt].

## Releasing

The DevTools extension ships **inside this package** at
`extension/devtools/`. It is built from the companion
[`arcane_framework_devtools_extension`][ext-repo] package (which declares
`publish_to: none` and is never published on its own). Releasing therefore
always ships framework + extension together.

Run the publish gate, which does everything below in one pass:

```sh
dart run tool/publish.dart --dry-run   # build + validate + publish dry-run
dart run tool/publish.dart             # build + validate + publish for real
```

The gate, from any directory:

1. Resolves the extension repo (`../arcane_framework_devtools_extension` by
   default; override with `--extension-path`, or clone automatically with
   `--extension-git-url`).
2. Fetches and fast-forwards it (uncommitted changes or a missing `origin`
   remote produce a warning, not a failure).
3. Writes a temporary `pubspec_overrides.yaml` in the extension repo pointing
   `arcane_framework` at this local checkout, so the build resolves even before
   the framework is on pub.dev (removed on exit).
4. Runs `flutter pub get`, `devtools_extensions build_and_copy` (into
   `extension/devtools/`), and `devtools_extensions validate` in the extension
   repo.
5. Asserts `extension/devtools/.pubignore` contains `!build` and
   `extension/devtools/build/` is non-empty — without the former, `pub publish`
   (which respects git ignore rules when no `.pubignore` overrides them) would
   **omit** the compiled output and silently ship an empty extension.
6. Runs `flutter pub publish` (`--dry-run` for the dry run).

### Manual steps

The gate automates the manual flow; run it by hand only when debugging:

```sh
# bump versions first (below), then, from the extension repo:
flutter pub get
dart run devtools_extensions build_and_copy --source=. --dest=../arcane_framework/extension/devtools
dart run devtools_extensions validate --package=../arcane_framework
# then, from this package:
flutter pub publish
```

### Before releasing

- Bump `extension/devtools/config.yaml` → `version:` for every user-visible
  extension change (independent of the framework version).
- Bump `pubspec.yaml` → `version:` for the framework release.
- Confirm `extension/devtools/.pubignore` exists and contains `!build`
  (re-includes the gitignored `build/` for publishing only).
- Update `CHANGELOG.md`.
- `dart analyze` must be clean in both this package and the extension repo.

`pub publish` warns (it does not fail) if `config.yaml` or a non-empty `build/`
directory is missing. **Do not ignore that warning.**

### Deploying

There is no separate deployment target. DevTools loads the extension's Flutter
web build from the installed package's `extension/devtools/build/` and renders
it in an iFrame. After publishing, users who depend on the new framework
version get the extension automatically — no separate install or deploy step.

[gh-issues]: https://github.com/hanskokx/arcane_framework/issues
[git-log-fmt]: http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html
[ext-repo]: https://github.com/hanskokx/arcane_framework_devtools_extension
