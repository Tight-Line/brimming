# Project Phases

Track progress by updating status: `[ ]` pending, `[~]` in progress, `[x]` complete

## Completed Phases

### Phase 1: Project Setup `[x]`
Rails 8.1 app with PostgreSQL 17, Docker Compose, RSpec, SimpleCov (100% coverage), RuboCop, GitHub Actions CI.

### Phase 3: Core Data Models `[x]`
User, Space, Question, Answer, Vote, QuestionVote, Comment, CommentVote, SpaceSubscription, SpaceModerator.

### Phase 4: Authentication `[x]`
Devise setup, registration, login/logout, password reset, session management.

### Phase 5: Core Q&A Features `[x]`
CRUD for Questions, Answers, Comments. Voting system. Answer ordering by score.

### Phase 6: Spaces & Moderation `[x]`
Space CRUD (admin only), Pundit policies, moderator management, solved answer designation.

### Phase 7: Web UI & Navigation `[x]`
Custom CSS, responsive layout, karma system, user badges.

### Phase 8: SSO - LDAP/ActiveDirectory `[x]`
Multiple LDAP servers, group-to-space mapping, user opt-out UI.

### Phase 10: Search Integration `[x]`
PostgreSQL FTS + pgvector semantic search, hybrid search, embedding providers, Sidekiq workers.

### Phase 12: Articles `[x]`
Multiple content types (Markdown, HTML, PDF, DOCX, XLSX, Web Page), content extraction, search integration.

### Phase 13: Bookmarks `[x]`
Polymorphic bookmarks for Questions, Answers, Comments, Articles. Turbo Stream updates.

### Phase 14: Chunking & RAG `[x]`
Content chunking, chunk embeddings, RAG query pipeline, citation support, prompt engineering.

## In Progress

### Phase 11: Background Workers & Email `[~]`
- [x] Sidekiq configuration and Web UI
- [ ] User email preferences
- [ ] DigestMailer
- [ ] Scheduled digest jobs

### Phase 15: Q&A Wizard `[~]`
- [x] Core wizard workflow
- [x] Generate from Articles, topics, knowledge base
- [x] "Helpful Robot" system user with sponsorship tracking
- [ ] Generate from uploaded documents
- [ ] Import from external FAQ sources
- [ ] Special FAQ styling/badge in UI

## Not Started

### Phase 16: REST API & Swagger
API namespace with versioning, token auth, Swagger/OpenAPI docs.

### Phase 17: MCP Server
Brimming as knowledge base backend for AI assistants. Tools: `retrieve()`, `ask()`, `list_spaces()`.

### Phase 18: Helm Chart Foundation
Kubernetes deployment with helm-unittest, PostgreSQL/Valkey subcharts.

### Phase 19: SSO - Social Providers
Google, Facebook, LinkedIn, GitHub, GitLab via OmniAuth.
