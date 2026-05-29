# Changelog

## v1.1.0 - 2026-05-30

### Added
- Git files page: view changed files with add/delete/modify status and line counts.
- Session list page: pick or create a session when opening a project.
- Command source badges: Skill / MCP / Cmd labels on command suggestions.
- Command suggestion sorting: skills first, then commands, then MCP.
- Session error notification: push notification when a session encounters an error.
- `source` field on Command model for command origin tracking.
- `FileStatus` model and `/file/status` API endpoint.
- `fileStatusProvider` for reactive git file status.

### Changed
- Project open flow now navigates to session list instead of directly to chat.
- Session error events now route to both unread indicator and notification handler.

## v1.0.0 - 2026-04-09

### Added
- Initial public release of FlyCode, a Flutter mobile client for connecting to `opencode server`.
- Project browsing and session management for quickly jumping into new or existing coding sessions.
- Mobile-optimized chat experience for interacting with coding agents, including streaming responses and markdown rendering.
- In-app support for reviewing permission requests, interactive questions, todos, diffs, and session context.
- Model and agent configuration, including provider-aware model selection and variant switching.
- File and image input workflows, including `@` file mentions, image attachments, and clipboard image paste support.
- Local persistence for app settings and session-related preferences, plus optional session completion notifications.
- Built-in app personalization with theme mode selection and multilingual localization support.
