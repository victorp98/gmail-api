# gmail-api

Local email API for applications that need Gmail-like inbox, sent-message, thread, history and label behavior without delivering mail to the Internet.

## Run locally

```bash
bin/setup
# Later runs:
bin/dev
```

Open `http://localhost:4567`. Data is stored in SQLite under `storage/`.

Docker is also supported with `docker compose up --build`.

## API

Mailbox email parameters must be URL encoded. Set `GMAIL_API_KEY` to require `Authorization: Bearer <key>`.

```bash
curl -X POST http://localhost:4567/api/v1/mailboxes/support%40example.com/messages \
  -H 'Content-Type: application/json' \
  -d '{"from":"customer@example.net","to":"support@example.com","subject":"Help","body":"Hello"}'

curl 'http://localhost:4567/api/v1/mailboxes/support%40example.com/messages?label=INBOX'

curl -X POST http://localhost:4567/api/v1/mailboxes/support%40example.com/send \
  -H 'Content-Type: application/json' \
  -d '{"from":"support@example.com","to":"customer@example.net","subject":"Re: Help","body":"Response","thread_id":"thread-1"}'
```

Additional endpoints:

- `GET /api/v1/mailboxes/:email/profile`
- `GET /api/v1/mailboxes/:email/messages?label=INBOX&after_history_id=10&limit=500`
- `GET /api/v1/mailboxes/:email/messages/:id`
- `PATCH /api/v1/mailboxes/:email/messages/:id/labels`
- `DELETE /api/v1/mailboxes/:email/messages`

This service never opens SMTP connections and never delivers messages externally.

## GitHub

Secrets, logs and SQLite databases are ignored. When the project is ready to publish:

```bash
git init
git add .
git commit -m "Initial gmail-api service"
git branch -M main
git remote add origin git@github.com:YOUR_ORG/gmail-api.git
git push -u origin main
```
