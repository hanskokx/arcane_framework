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

[gh-issues]: https://github.com/hanskokx/arcane_framework/issues
[git-log-fmt]: http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html
