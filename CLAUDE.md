# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project: Brimming

A Stack Overflow-style Q&A platform built with Ruby on Rails.

**Developed by [Tight Line LLC](https://www.tightlinesoftware.com)**

Open-source project hosted on GitHub under the MIT License.

### Core Concepts
- **Questions** belong to **Spaces** and are posted by **Users**
- **Answers** belong to Questions and are posted by Users
- Users **vote** on Questions, Answers, and Comments (up/down for Q&A, upvote-only for comments)
- Answers are displayed sorted by vote score (highest first)
- Space **moderators** can mark one Answer as **"Solved"** for a Question
- **Best Answer** = highest-voted answer for a question (may differ from Solved)
- **Karma** system rewards participation: +5 questions, +10 answers, +15 solved, +1 per upvote
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

### LDAP Group-to-Space Mapping
- Admins can configure multiple LDAP servers
- Each LDAP server can have group-to-space mappings:
  - Map LDAP group names (fully-qualified DN or partial match) to one or more Spaces
  - Auto-registration into mapped Spaces happens at login time
- Users can opt-out of auto-registered Spaces
- System persists opt-out choices via `SpaceOptOut` model
- On subsequent logins, opted-out Spaces are skipped even if LDAP group still matches

### Authorization Roles
- **User**: Post questions, post answers, vote
- **Moderator** (per-space): Mark correct answers, moderate content
- **Admin**: Manage spaces, assign moderators, configure SSO, manage LDAP mappings

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

### Phase 3: Core Data Models `[x]`
- User (email, username, full_name, avatar_url, role)
- Space (name, slug, description)
- Question (title, body, user_id, space_id, vote_score, views_count, edited_at)
- Answer (body, user_id, question_id, is_correct, vote_score, edited_at)
- Vote (user_id, answer_id, value: +1/-1)
- QuestionVote (user_id, question_id, value: +1/-1)
- Comment (body, user_id, commentable polymorphic, parent_id for nesting, vote_score, edited_at)
- CommentVote (user_id, comment_id)
- SpaceSubscription (user_id, space_id)
- SpaceModerator (user_id, space_id)
- Database migrations with proper indexes and constraints

### Phase 4: Authentication Foundation `[x]`
- Devise setup for User model `[x]`
- Registration (email + username + password) `[x]`
- Login/logout `[x]`
- Password reset (Devise recoverable) `[x]`
- Session management (Devise rememberable) `[x]`
- Basic authorization helper methods `[x]`

### Phase 5: Core Q&A Features `[x]`
- Questions: full CRUD (create, read, edit, delete own) `[x]`
- Answers: full CRUD (create, read, edit, delete own) `[x]`
- Comments: full CRUD with nested replies `[x]`
- Voting on questions (one vote per user per question) `[x]`
- Voting on answers (one vote per user per answer) `[x]`
- Voting on comments (upvote only) `[x]`
- Answer ordering by vote score `[x]`
- Question show page with answers `[x]`

### Phase 6: Spaces & Moderation `[~]`
- Space CRUD (admin only) - **read only implemented**
- SpaceModerator join model `[x]`
- Pundit policies for authorization `[ ]`
- Moderator: mark answer as solved (is_correct) `[x]`
- Admin: assign/remove moderators - **seed data only**

### Phase 7: Web UI & Navigation `[x]`
- Custom CSS styling (no framework) `[x]`
- Responsive layout with header navigation `[x]`
- Home page: recent questions with space filtering `[x]`
- Space browsing and filtering `[x]`
- User profile page with stats `[x]`
- Gamification: karma system, solved answers count, best answers count `[x]`
- User badge component showing karma, solved count, best answer count `[x]`

### Phase 8: SSO - LDAP/ActiveDirectory `[ ]`
- OmniAuth LDAP strategy
- LdapServer model (name, host, port, encryption, bind_dn, bind_password, user_search_base, group_search_base)
- Support for multiple LDAP servers
- Admin UI to add/edit/remove LDAP servers
- LdapGroupMapping model (ldap_server_id, group_pattern, pattern_type: exact|prefix|suffix|contains)
- LdapGroupMappingSpace join (ldap_group_mapping_id, space_id)
- SpaceOptOut model (user_id, space_id, ldap_group_mapping_id)
- Auto-registration service that runs at login:
  1. Fetch user's LDAP groups
  2. Match against configured patterns
  3. Subscribe user to mapped Spaces (skip if opted-out)
- User UI to view and opt-out of LDAP-assigned Spaces

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
- Search UI with filters (space, date, votes)

### Phase 11: Background Workers & Email `[ ]`
- Sidekiq configuration
- User email preferences (per-post, daily digest, weekly digest, none)
- SpaceSubscription model
- DigestMailer
- Scheduled jobs for daily/weekly digests

### Phase 12: REST API `[ ]`
- API namespace with versioning (api/v1)
- Token authentication (Devise tokens or JWT)
- Full CRUD endpoints for all resources
- API documentation (Swagger/OpenAPI or Rswag)

### Phase 13: MCP Server `[ ]`
- MCP protocol integration
- Tool: list_spaces
- Tool: search_questions(query, spaces[])
- Tool: get_answers(question_id, limit, best_only)
- Admin-configurable answer limit
- **Update Helm chart** if MCP requires separate service/port
- **Update Helm tests** if architecture changes

---

## Current Status

**Completed Phases**: 1, 3, 4, 5, 7
**In Progress**: 6 (Moderation - need Pundit policies, admin UI)
**Not Started**: 2 (Helm), 8-13

### What's Working
- Full data model with Users, Spaces, Questions, Answers, Comments, Votes
- Devise authentication with registration (username + email + password), login/logout
- Full web UI for browsing and creating questions, answers, and comments
- Voting system for questions, answers, and comments (with Turbo Stream updates)
- Nested comments with replies (up to 3 levels deep)
- Karma system with gamification (questions, answers, solved, best answers, votes)
- User badges showing karma, solved answer count, best answer count
- Space subscriptions and moderator assignments (via seeds)
- "Solved" designation for moderator-approved answers
- "Best" designation for highest-voted answers per question
- Sign-in modal for unauthenticated users attempting protected actions
- 100% test coverage

### Next Actions
1. **Phase 6 (Authorization)**: Add Pundit policies for role-based access, admin UI for spaces
2. **Phase 2 (Helm)**: Create Kubernetes deployment charts

---

## Code Conventions

- Models in `app/models/`
- Request specs preferred over controller specs
- Service objects in `app/services/` for complex operations
- Pundit policies in `app/policies/`
- Background jobs in `app/jobs/`
- Use `frozen_string_literal: true` in all Ruby files
- Prefer `let` and `let!` in RSpec over instance variables

### Definition of Done

Work is **not finished** until:
1. **Test coverage is 100%** (line and branch) - run `make test`
2. **Linting is clean** (no RuboCop offenses) - run `make lint`

Always verify both before considering any task complete.

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
