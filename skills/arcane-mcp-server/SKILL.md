---
name: arcane-mcp-server
description: Using the arcane_framework MCP server to discover running Flutter apps and read or mutate their state by Bridge (services, logs, feature flags, authentication, theme, environment).
---

# The arcane_framework MCP server

Use this skill when you act as an MCP client (or write automation) against the
arcane_framework server: `dart run arcane_mcp_server` over stdio, or the
`ArcaneMcpServer` class embedded in a host process.

## Overview

The server speaks Model Context Protocol over stdio, discovers running Flutter
apps through the Dart Tooling Daemon, connects to a chosen app's VM service,
and mirrors the app's bridge methods as tools and resources. Any app that
mounts `ArcaneApp` registers the bridge extension automatically.

Run it:

```sh
dart run arcane_mcp_server
```

## Tools

- `find_apps` — list running arcane_framework apps discovered via DTD.
  Optional `dtdUri` restricts discovery to one Dart Tooling Daemon.
- `connect_app` — attach to an app. Pass `name`, `appUri`, or `dtdUri`;
  alternatively pass a raw `vmServiceUri`. Several apps can be connected at
  once.
- `get_services` — registered `ArcaneService`s with a per-type summary.
- `get_logs` — recent log events; filter with `level`, `module`, `search`, and
  cap with `limit`.
- `get_feature_flags` / `set_feature_flag` — read flags, or enable/disable one
  by `name` with `enabled`.
- `get_authentication` — current auth state; pass `includeTokens: true` to
  include access/refresh tokens.
- `get_theme` / `set_theme_mode` — theme state; set `mode` to "light",
  "dark", or "system".
- `get_environment` / `set_environment` — current environment; set by `name`.

## Resources

`arcane://overview`, `arcane://services`, `arcane://logs`,
`arcane://feature_flags`, `arcane://authentication`, `arcane://theme`,
`arcane://environment` — JSON text mirrors of the `get_*` tools, rendered with
the app's latest state. Any other `arcane://*` URI returns an explanatory
"Unknown resource" body rather than an error.

## Targeting

- The **first connected app is the default** for tools and resources.
- With several apps connected, pass `appName` (or `appUri`) to any tool or use
  a matching `appName` to target a specific app.
- Prefer `connect_app` with a discovered `name`/`appUri`; use `vmServiceUri`
  to attach to a bare VM service URI directly.

## Wire protocol

Shared between framework, server, and DevTools extension — see
`lib/src/mcp/protocol.dart`:

- `arcaneMcpServiceExtension` = `ext.arcane.devtools.invoke`
- Response shapes: result `{"type":"result","result":<data>}`; error
  `{"type":"error","error":"<message>"}`.

## Guidance

- Connect before calling state tools; otherwise you get a clear "No app
  connections." error.
- Keep mutations minimal and targeted: use `appName` so you don't change the
  wrong app when several are connected.
- When adding capabilities, update `serverArguments`/tools in
  `ArcaneMcpServer`, the resources in `_registerResources`, and keep
  `lib/src/mcp/protocol.dart` as the single schema source.