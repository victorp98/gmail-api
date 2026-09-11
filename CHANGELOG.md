# Changelog

## [0.2.0] - 2026-09-11

### Added

- Added multiple MIME attachments to incoming messages, outgoing messages and replies in the local mailbox UI.
- Added base64-encoded attachments to the JSON API for document-ingestion tests.

## [0.1.0] - 2026-08-31

### Added

- Added isolated mailboxes with SQLite persistence.
- Added incoming and sent message capture with MIME bodies, threads and incremental history IDs.
- Added inbox, sent and spam label operations.
- Added a versioned JSON API with optional bearer-token authentication.
- Added a responsive browser interface for inspecting mailboxes and injecting incoming messages.
- Added Docker Compose support and integration documentation.
