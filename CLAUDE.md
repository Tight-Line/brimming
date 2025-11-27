# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project: Brimming

A Stack Overflow-style Q&A platform built with Ruby on Rails.

**Developed by [Tight Line LLC](https://www.tightlinesoftware.com)**

Open-source project hosted on GitHub under the MIT License.

### Core Concepts
- **Questions** belong to **Categories** and are posted by **Users**
- **Answers** belong to Questions and are posted by Users
- Users **vote** on Answers (up/down)
- Answers are displayed sorted by vote score (highest first)
- Category **moderators** can mark one Answer as "correct" for a Question
- User identity is their RFC 5322 email address; they choose a display username and optional avatar

### Tech Stack
- Ruby 3.4.7
- Ruby on Rails 8.1
- PostgreSQL 18.1 (primary database)
- Valkey 9.0 (Redis-compatible, for caching and Sidekiq)
- OpenSearch 3.2 (full-text search for questions/answers)
- Sidekiq (background jobs)
- Docker Compose (local development)
- Helm 3.x (Kubernetes deployment)
- RSpec (test framework - 100% coverage required)
- GitHub Actions (CI/CD)

### Architecture
```
docker-compose.dev.yml (local dev)
├── dev (Rails development container)
├── postgres
├── valkey
└── opensearch (Phase 10)

docker-compose.yml (production-like)
├── app (Rails: Web UI + API + MCP server)
├── worker (Sidekiq)
├── postgres
├── valkey
└── opensearch

helm/brimming/ (Kubernetes)
├── app (Deployment + Service)
├── worker (Deployment)
├── postgres (StatefulSet or external)
├── valkey (StatefulSet or external)
└── opensearch (StatefulSet or external)
```

### Authentication
- Local auth via Devise
- SSO via modular OmniAuth strategy:
  - **LDAP/ActiveDirectory**: Multiple servers supported, admin-configurable
  - **Social**: Google, Facebook, LinkedIn, GitHub, GitLab (admin-toggleable)

### LDAP Group-to-Category Mapping
- Admins can configure multiple LDAP servers
- Each LDAP server can have group-to-category mappings:
  - Map LDAP group names (fully-qualified DN or partial match) to one or more Categories
  - Auto-registration into mapped Categories happens at login time
- Users can opt-out of auto-registered Categories
- System persists opt-out choices via `CategoryOptOut` model
- On subsequent logins, opted-out Categories are skipped even if LDAP group still matches

### Authorization Roles
- **User**: Post questions, post answers, vote
- **Moderator** (per-category): Mark correct answers, moderate content
- **Admin**: Manage categories, assign moderators, configure SSO, manage LDAP mappings

---

## Development Commands

All commands use the Makefile for consistency. Run `make help` to see all available targets.

```bash
# Initial setup
make setup

# Start/stop services
make up
make down
make restart
make logs

# Development
make shell      # Open bash in dev container
make console    # Rails console
make server     # Start Rails server at localhost:3000

# Database
make db-create
make db-migrate
make db-rollback
make db-reset   # Drop, create, migrate, seed
make db-seed

# Testing (100% coverage required)
make test           # Run all tests
make test-models    # Model specs only
make test-requests  # Request specs only
make test-jobs      # Job specs only

# Code quality
make lint       # RuboCop
make lint-fix   # RuboCop with auto-fix
make security   # Brakeman + bundler-audit

# Helm
make helm-lint
make helm-test

# Full CI pipeline
make ci
```

---

## Project Phases

Track progress by updating status: `[ ]` pending, `[~]` in progress, `[x]` complete

### Phase 1: Project Setup `[x]`
- Rails 8.1 app with PostgreSQL 18.1
- Docker Compose dev environment (dev, postgres, valkey)
- RSpec + FactoryBot + Shoulda Matchers configured
- SimpleCov for coverage reporting (100% target)
- RuboCop configured
- GitHub Actions CI workflow
- README.md with badges (CI status, coverage)
- CONTRIBUTING.md, CODE_OF_CONDUCT.md, LICENSE (MIT)
- Makefile with standard targets

### Phase 2: Helm Chart Foundation `[ ]`
- Create `helm/brimming/` chart structure
- Chart.yaml with proper metadata
- values.yaml with sensible defaults
- Templates for initial workloads:
  - app Deployment + Service + Ingress
  - worker Deployment
  - ConfigMap for Rails config
  - Secret template for credentials
- PostgreSQL and Valkey as optional subcharts or external
- Helm chart tests using helm-unittest
- CI step to lint and test Helm chart
- **NOTE**: Update Helm chart tests whenever adding new workloads

### Phase 3: Core Data Models `[ ]`
- User (email, username, avatar_url, role)
- Category (name, slug, description)
- Question (title, body, user_id, category_id)
- Answer (body, user_id, question_id, is_correct)
- Vote (user_id, answer_id, value: +1/-1)
- Database migrations with proper indexes and constraints

### Phase 4: Authentication Foundation `[ ]`
- Devise setup for User model
- Registration (email + username + password)
- Login/logout
- Password reset
- Session management
- Basic authorization helper methods

### Phase 5: Core Q&A Features `[ ]`
- Questions CRUD (create, read, update, delete own)
- Answers CRUD
- Voting on answers (one vote per user per answer)
- Answer ordering by vote score
- Question show page with answers

### Phase 6: Categories & Moderation `[ ]`
- Category CRUD (admin only)
- CategoryModerator join model
- Pundit policies for authorization
- Moderator: mark answer as correct
- Admin: assign/remove moderators

### Phase 7: Web UI & Navigation `[ ]`
- Tailwind CSS or Bootstrap setup
- Responsive layout with collapsible sidebar
- Home page: top questions for user's followed categories
- Category browsing and filtering
- User profile page
- Gamification stats display (questions/answers/best-answers count)

### Phase 8: SSO - LDAP/ActiveDirectory `[ ]`
- OmniAuth LDAP strategy
- LdapServer model (name, host, port, encryption, bind_dn, bind_password, user_search_base, group_search_base)
- Support for multiple LDAP servers
- Admin UI to add/edit/remove LDAP servers
- LdapGroupMapping model (ldap_server_id, group_pattern, pattern_type: exact|prefix|suffix|contains)
- LdapGroupMappingCategory join (ldap_group_mapping_id, category_id)
- CategoryOptOut model (user_id, category_id, ldap_group_mapping_id)
- Auto-registration service that runs at login:
  1. Fetch user's LDAP groups
  2. Match against configured patterns
  3. Subscribe user to mapped Categories (skip if opted-out)
- User UI to view and opt-out of LDAP-assigned Categories

### Phase 9: SSO - Social Providers `[ ]`
- OmniAuth strategies: Google, Facebook, LinkedIn, GitHub, GitLab
- SsoProvider model (provider, enabled, client_id, client_secret)
- Admin UI to enable/configure providers
- Account linking for existing users

### Phase 10: OpenSearch Integration `[ ]`
- Add OpenSearch to Docker Compose
- **Update Helm chart**: Add OpenSearch StatefulSet or external config
- **Update Helm tests** for new workload
- Searchkick or Elasticsearch-Rails gem
- Index Questions and Answers
- Search API endpoint
- Search UI with filters (category, date, votes)

### Phase 11: Background Workers & Email `[ ]`
- Sidekiq configuration
- User email preferences (per-post, daily digest, weekly digest, none)
- CategorySubscription model
- DigestMailer
- Scheduled jobs for daily/weekly digests

### Phase 12: REST API `[ ]`
- API namespace with versioning (api/v1)
- Token authentication (Devise tokens or JWT)
- Full CRUD endpoints for all resources
- API documentation (Swagger/OpenAPI or Rswag)

### Phase 13: MCP Server `[ ]`
- MCP protocol integration
- Tool: list_categories
- Tool: search_questions(query, categories[])
- Tool: get_answers(question_id, limit, best_only)
- Admin-configurable answer limit
- **Update Helm chart** if MCP requires separate service/port
- **Update Helm tests** if architecture changes

---

## Current Status

**Current Phase**: Phase 1 Complete
**Next Action**: Begin Phase 2 - Helm Chart Foundation (or Phase 3 - Core Data Models)

---

## Code Conventions

- Models in `app/models/`
- Request specs preferred over controller specs
- Service objects in `app/services/` for complex operations
- Pundit policies in `app/policies/`
- Background jobs in `app/jobs/`
- Use `frozen_string_literal: true` in all Ruby files
- Prefer `let` and `let!` in RSpec over instance variables

---

## Helm Chart Guidelines

- Chart lives in `helm/brimming/`
- Use helm-unittest for chart tests (in `helm/brimming/tests/`)
- **Every new workload requires**:
  1. Template in `templates/`
  2. Values in `values.yaml`
  3. Test in `tests/`
- CI runs: `helm lint`, `helm template | kubeval`, `helm unittest`
- Support both bundled (subchart) and external modes for:
  - PostgreSQL
  - Valkey
  - OpenSearch

---

## Repository Structure

```
/
├── .github/
│   ├── workflows/
│   │   └── ci.yml            # CI pipeline (lint, test, security, helm, build)
│   ├── ISSUE_TEMPLATE/
│   └── PULL_REQUEST_TEMPLATE.md
├── helm/
│   └── brimming/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── templates/
│       └── tests/
├── spec/
│   ├── factories/            # FactoryBot factories
│   ├── models/
│   ├── requests/
│   ├── jobs/
│   └── support/
├── CLAUDE.md                  # This file (AI assistant context)
├── .cursorrules               # Cursor AI context (points to CLAUDE.md)
├── .clinerules                # Cline AI context (points to CLAUDE.md)
├── README.md                  # Project intro, badges, setup
├── CONTRIBUTING.md            # Contribution guidelines
├── CODE_OF_CONDUCT.md         # Community standards
├── LICENSE                    # MIT License
├── Makefile                   # All development commands
├── docker-compose.yml         # Production-like local environment
├── docker-compose.dev.yml     # Development environment
├── Dockerfile                 # Production image
├── Dockerfile.dev             # Development image
└── ... (Rails app structure)
```
