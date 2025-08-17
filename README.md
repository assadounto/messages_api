#  Messages API (Inbox)

A Rails API that accepts inbound messages, classifies them **asynchronously** via a simulated “LLM API,” retries on transient failures, and exposes results.

---

## Features

- `POST /api/v1/messages` — accept `{subject, body, sender}` and **queue** classification.
- Background job retries up to **3** times (with backoff) on transient errors.
- Simulated external service (“LLM API”) randomly fails and classifies **important** vs **general**.
- `GET /api/v1/messages` — list messages with status, classification, attempts, and last error.
- Tracks the number of **attempts** (bonus).

---

## Requirements

- Ruby 3.x, Rails 7.x  
- PostgreSQL 13+  
- Bundler (`gem install bundler`)  
- (Optional) Redis + Sidekiq (for production-style queues)

---

## Setup

```bash
# Install gems
bundle install

# Create & migrate DB
bin/rails db:create db:migrate
```

If Postgres isn’t default, export env vars or edit `config/database.yml`:

```bash
export PGUSER=postgres
export PGPASSWORD=secret
export PGHOST=localhost
export PGPORT=5432
```

**Job adapter (dev default):** `config/application.rb` uses Rails `:async`.  
For production, switch to Sidekiq (see below).

---

## Run

```bash
bin/rails s
# Server: http://localhost:3000
```

Rails’ async executor will process jobs in-process.

---

## API

### Create a message (queues classification)

`POST /api/v1/messages`

```bash
curl -X POST http://localhost:3000/api/v1/messages   -H "Content-Type: application/json"   -d '{
    "message": {
      "subject": "Need this ASAP",
      "body": "Please review before EOD.",
      "sender": "ceo@company.com"
    }
  }'
```

**202 Accepted**
```json
{
  "id": 1,
  "subject": "Need this ASAP",
  "sender": "ceo@company.com",
  "body": "Please review before EOD.",
  "status": "pending",
  "classification": null,
  "attempts": 0,
  "last_error": null,
  "classified_at": null,
  "created_at": "2025-08-17T12:34:56Z"
}
```

### List messages (with results)

`GET /api/v1/messages`

```bash
curl http://localhost:3000/api/v1/messages
```

**200 OK**
```json
[
  {
    "id": 1,
    "subject": "Need this ASAP",
    "sender": "ceo@company.com",
    "body": "Please review before EOD.",
    "status": "classified",
    "classification": "important",
    "attempts": 1,
    "last_error": null,
    "classified_at": "2025-08-17T12:35:10Z",
    "created_at": "2025-08-17T12:34:56Z"
  }
]
```

---

## How It Works

- **Model:** `Message` with enums  
  - `status`: `pending`, `classified`, `failed`  
  - `classification`: `important`, `general` (nullable while pending/failed)  
  - `classification_attempts` increments each job run

- **Job:** `ClassifyMessageJob`  
  - Calls `ExternalLlmClient.classify(...)`  
  - On success → `status: classified`, sets `classification`, `classified_at`  
  - On transient failure → re-enqueue with backoff (5s, 15s, 30s) up to **3** attempts  
  - After 3 failures → `status: failed`, stores `last_error`

- **Simulated LLM:** `ExternalLlmClient`  
  - ~20% chance to raise a transient error  
  - Classifies as **important** if subject/body contains `urgent`/`asap` or sender includes `ceo`; else **general**

---

## Quick Smoke Test

```bash
# General
curl -X POST http://localhost:3000/api/v1/messages   -H "Content-Type: application/json"   -d '{"message":{"subject":"FYI","body":"nothing urgent","sender":"team@company.com"}}'

# Likely important
curl -X POST http://localhost:3000/api/v1/messages   -H "Content-Type: application/json"   -d '{"message":{"subject":"URGENT: prod issue","body":"ASAP please","sender":"ops@company.com"}}'
```

Then list:
```bash
curl http://localhost:3000/api/v1/messages
```

---

## Optional: Sidekiq (Production-like Queues)

1) Add to `Gemfile`:
```ruby
gem "sidekiq"
```
```bash
bundle install
```

2) Configure adapter (`config/application.rb`):
```ruby
config.active_job.queue_adapter = :sidekiq
```

3) Run Redis & Sidekiq:
```bash
redis-server
bundle exec sidekiq
```

4) Start Rails:
```bash
bin/rails s
```

---

## Troubleshooting

- **Pending forever**  
  - In dev with `:async`, ensure the server stays running.  
  - With Sidekiq, confirm Redis + Sidekiq are running.

- **Postgres connection refused**  
  - Verify DB credentials/host/port; re-run `bin/rails db:create db:migrate`.

- **422 Unprocessable Entity** on `POST /messages`  
  - Ensure JSON is nested under `message` with `subject`, `body`, and `sender` present.

- **CORS** (for browser clients)  
  - Add `rack-cors` and configure allowed origins.

---

## Project Structure (key files)

```
app/models/message.rb                 # Model + enums + validations
app/jobs/classify_message_job.rb      # Background job with retries/backoff
app/services/external_llm_client.rb   # Simulated LLM API (flaky)
app/controllers/api/v1/messages_controller.rb
config/routes.rb                      # /api/v1/messages endpoints
```

---

## License

MIT 
