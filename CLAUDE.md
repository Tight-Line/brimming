# CLAUDE.md

## Project: Brimming

A Stack Overflow-style Q&A platform built with Ruby on Rails.

**Developed by [Tight Line LLC](https://www.tightlinesoftware.com)** | MIT License

---

## Quick Reference

| What | Command |
|------|---------|
| Run tests | `make test` |
| Run linter | `make lint` |
| Fix lint | `make lint-fix` |
| Rails console | `make console` |
| Start server | `make up` then http://localhost:33000 |
| Run RSpec directly | `docker-compose -f docker-compose.dev.yml exec -T dev env RAILS_ENV=test bundle exec rspec` |

**Definition of Done**: 100% test coverage (line + branch) AND clean linting.

---

## Core Domain Model

```
Users post Questions in Spaces
  └── Questions have Answers (voted, sortable)
        └── Moderators mark one Answer as "Solved"
  └── Questions, Answers, Comments support voting
  └── Comments nest up to 3 levels deep

Articles = long-form content (Markdown, PDF, Web Page imports)
  └── Belong to multiple Spaces
  └── Upvote-only (no downvotes)
  └── Chunked for RAG retrieval

Bookmarks = user saves for Questions, Answers, Comments, Articles
```

**Karma**: +5 questions, +10 answers, +15 solved, +1 per upvote

---

## Tech Stack

- **Ruby 3.4.7** / **Rails 8.1**
- **PostgreSQL 17** with pgvector + pg_trgm
- **Valkey 9.0** (Redis-compatible)
- **Sidekiq** (background jobs)
- **Docker Compose** (development)
- **RSpec** (100% coverage required)

---

## Architecture

```
docker-compose.dev.yml
├── app        (Rails web server, port 33000)
├── dev        (Shell/console container)
├── worker     (Sidekiq)
├── postgres   (pgvector + pg_trgm + firecrawl schema)
├── valkey     (db0: Rails/Sidekiq, db1: Firecrawl)
├── openldap   (test LDAP server)
├── mailhog    (email testing, port 33025)
└── firecrawl  (optional web scraper, port 33002)
```

---

## Key Patterns

### Authentication & Authorization
- **Devise** for local auth
- **OmniAuth** for LDAP/SSO (multiple servers, group-to-space mapping)
- **Pundit** policies in `app/policies/`

### Search (Hybrid)
Vector-first with keyword fallback. See @docs/search-architecture.md

### Content Import
Articles can import web pages via Jina.ai or self-hosted Firecrawl.
See @docs/firecrawl-setup.md

### AI Features
- **Embedding providers**: OpenAI, Cohere, Ollama, etc. at `/admin/embedding_providers`
- **LLM providers**: For Q&A Wizard at `/admin/llm_providers`
- **RAG prompts**: `config/prompts/`

---

## Code Conventions

- `frozen_string_literal: true` in all Ruby files
- Request specs preferred over controller specs
- Service objects in `app/services/`
- Background jobs in `app/jobs/`
- Use `let`/`let!` in RSpec, not instance variables

### Important Rules

**Never add unreachable code.** Don't add `else` branches for impossible cases (e.g., polymorphic types that can't exist). This creates untestable code.

**Never hardcode env values in tests.** Use constants or Rails config.

---

## Project Status

See @docs/phases.md for full roadmap.

**Completed**: Setup, Core Models, Auth, Q&A, Spaces, UI, LDAP SSO, Search, Articles, Bookmarks, RAG/Chunking
**In Progress**: Email digests, Q&A Wizard enhancements
**Not Started**: REST API, MCP Server, Helm Chart, Social SSO

---

## Session Plans

For non-trivial tasks, maintain a plan file at `.claude/session-plan.md`:

```markdown
# Session Plan: [Task]

## Status: [Planning | In Progress | Testing | Complete]

## Completed
- [x] Step 1 (files: path/to/file.rb)

## Remaining
- [ ] Step 2

## Key Decisions
- Decision: rationale
```

Update after each round of edits. This survives context compaction.

---

## Additional Documentation

- @docs/phases.md - Project roadmap and phase details
- @docs/search-architecture.md - Hybrid search implementation
- @docs/firecrawl-setup.md - Self-hosted web scraper setup
- @docs/technical-debt.md - Known issues and workarounds
