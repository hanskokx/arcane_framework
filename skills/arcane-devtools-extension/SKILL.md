---
name: arcane-devtools-extension
description: Building, validating, and iterating on the arcane_framework DevTools extension, including the extension manifest, build_and_copy, and the shared VM service extension protocol.
---

# The arcane_framework DevTools extension

Use this skill when you work on the DevTools extension that inspects and
mutates running arcane_framework apps.

## Repository layout

- **`extension/devtools/`** in `arcane_framework` holds only the *built*
  extension plus its manifest:
  - `config.yaml` — the DevTools extension manifest (see below).
  - `build/` — the compiled Web app that DevTools serves. Never edited by
    hand; regenerate it with `build_and_copy`.
- The extension **source lives in the companion repo**
  `hanskokx/arcane_framework_devtools_extension`. Production code never
  imports `extension/devtools`; it is a dev-time artifact of that repo.

## Manifest (`extension/devtools/config.yaml`)

```yaml
name: arcane_framework
issueTracker: https://github.com/hanskokx/arcane_framework/issues
version: 1.0.0
materialIconCodePoint: "0xe50a"
requiresConnection: true
```

- `name` is the DevTools "extension id" shown in the DevTools tab bar.
- `materialIconCodePoint` is the codepoint of the tab icon (Material Icons).
- `requiresConnection: true` hides the extension until an app is connected so
  the tab has a live VM service handle.

## Build workflow (CI does this, reproduce locally)

From the companion repo, with `pubspec_overrides.yaml` pointing
`arcane_framework` at your local checkout:

```sh
flutter pub get
dart run devtools_extensions build_and_copy --source=. --dest=../arcane_framework/extension/devtools
dart run devtools_extensions validate --package=../arcane_framework
```

The GitHub Actions workflow `.github/workflows/extension-build.yaml` checks out
both repos, injects the `dependency_overrides`, runs the two commands above,
and fails the PR if the extension does not validate. Paths that trigger it:
`lib/**`, `extension/**`, `pubspec.yaml`, `pubspec.lock`, `example/**`.

## Talking to the app

The extension drives the running app through the same bridge the MCP server
uses:

- Extension name: `ext.arcane.devtools.invoke` (`arcaneMcpServiceExtension`).
- Invoke it with `callServiceExtension` on the app's VM service. Parameters
  are JSON: `method` (an `ArcaneMcpMethods` name) plus `params` — the
  JSON-encoded argument map.
- Responses follow `arcaneMcpBuildResult`/`arcaneMcpBuildError`:
  - Result: `{"type": "result", "result": <data>}`
  - Error: `{"type": "error", "error": "<message>"}`
- The bridge decodes with `arcaneMcpDecode`; see `lib/src/mcp/protocol.dart`
  for the shared method/param constants.

Keep the extension and the MCP server on the **same** wire protocol — extend
`lib/src/mcp/protocol.dart` when you add new methods or parameters, never
duplicating the schema in the extension repo.

## Constraints

- There is **no Flutter test suite** that compiles for the extension
  (`devtools_app_shared` and `dart:js_interop` are not testable under the
  framework's test setup). The gate is `dart run devtools_extensions validate`
  and a successful `build_and_copy`.
- Rebuild the checked-in `build/` output whenever the extension source
  changes; a PR touching `extension/**` without a fresh build fails the CI
  extension job's intent.
- The extension is not published to pub.dev — DevTools serves it from the
  `extension/devtools` directory of the consuming app.