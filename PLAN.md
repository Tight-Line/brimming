# Phase 12: Articles - Implementation Plan

## Overview

Introduce Articles as long-form, authoritative content that can be attached to multiple spaces. This phase also introduces chunking for all content (articles, questions, answers, comments) to improve RAG retrieval precision.

## Data Model

### New Models

```ruby
# SpacePublisher - new role for content publishers (can publish articles but not moderate)
SpacePublisher
├── user_id
├── space_id
├── created_at

# Article - core article entity (space-agnostic)
Article
├── id
├── title (string, required)
├── body (text - stores raw content or extracted text)
├── content_type (string: html, markdown, pdf, docx, xlsx, etc.)
├── original_file (ActiveStorage attachment for non-text formats)
├── context (text - publisher-provided context for search/RAG)
├── user_id (author/uploader)
├── slug (for URLs)
├── created_at / updated_at / edited_at / last_editor_id
└── deleted_at (soft delete)

# ArticleSpace - join table (articles can be in multiple spaces)
ArticleSpace
├── article_id
├── space_id
├── attached_by_id (user who attached it)
├── created_at

# Chunk - polymorphic chunking for RAG (replaces questions.embedding)
Chunk
├── id
├── chunkable_type (Article, Question)
├── chunkable_id
├── chunk_index (ordering within parent)
├── content (text - the chunk content)
├── token_count (integer - for context window management)
├── embedding (vector)
├── embedded_at
├── embedding_provider_id
└── metadata (jsonb - source info like "answer_id", "comment_id", etc.)
```

### Changes to Existing Models

```ruby
# EmbeddingProvider - add chunking configuration
+ chunk_size (integer, default: 500 tokens)
+ chunk_overlap (integer, default: 50 tokens)

# Question - remove embedding columns (migrating to chunks)
- embedding
- embedded_at
- embedding_provider_id

# Comment - already polymorphic (commentable), will work with articles
```

## Authorization Rules

**SpacePublisher** (new role):
- Can create/edit/delete articles
- Can attach/detach articles to/from spaces where they are publisher
- Cannot moderate other users' content (questions, answers, comments)

**SpaceModerator** (existing):
- All SpacePublisher abilities, plus:
- Can moderate content in their spaces

**Admin**:
- All abilities across all spaces

**Article-specific rules**:
- Publisher/Moderator/Admin of ANY space the article is attached to can edit it
- Can only attach article to spaces where user is publisher/moderator/admin
- Articles can exist without space attachments (orphaned) - highlighted in admin dashboard

## Chunking Strategy

### What Gets Chunked

1. **Articles**: context + body + comments (as one document, re-chunked on changes)
2. **Questions**: title + body + answers + comments (as one thread, re-chunked on changes)

### Chunk Configuration (per EmbeddingProvider)

- `chunk_size`: Target size in tokens (default: 500)
- `chunk_overlap`: Overlap between chunks (default: 50)

### Chunk Metadata

Store source information in `metadata` jsonb:
```json
{
  "source_type": "answer",
  "source_id": 123,
  "position": "middle"
}
```

This allows citations to link back to specific answers/comments.

## Implementation Steps

### Step 1: SpacePublisher Model
- [ ] Migration: create_space_publishers
- [ ] Model: SpacePublisher with validations
- [ ] Add `publisher?` helper to User model
- [ ] Update Space model with `publishers` association
- [ ] Factory and specs

### Step 2: EmbeddingProvider Chunking Config
- [ ] Migration: add chunk_size and chunk_overlap to embedding_providers
- [ ] Update EmbeddingProvider model with defaults
- [ ] Update admin UI to configure chunk settings
- [ ] Specs

### Step 3: Chunk Model
- [ ] Migration: create_chunks (polymorphic, with vector column)
- [ ] Model: Chunk with validations and associations
- [ ] Add HNSW index for vector search (like current questions index)
- [ ] Factory and specs

### Step 4: ChunkingService
- [ ] Service to split text into overlapping chunks
- [ ] Token counting (using tiktoken or approximation)
- [ ] Preserve metadata about chunk source
- [ ] Specs with various content sizes

### Step 5: Article Model
- [ ] Migration: create_articles
- [ ] Model: Article with validations, slug generation
- [ ] ActiveStorage attachment for original_file
- [ ] Associations: user, article_spaces, comments (polymorphic)
- [ ] Factory and specs

### Step 6: ArticleSpace Model
- [ ] Migration: create_article_spaces
- [ ] Model: ArticleSpace join table
- [ ] Associations on Article and Space
- [ ] Specs

### Step 7: Content Extraction Service
- [ ] Service to extract text from various formats
- [ ] HTML: strip tags, preserve structure
- [ ] Markdown: render to text or keep as-is
- [ ] PDF: use pdf-reader gem
- [ ] Word: use docx gem
- [ ] Spreadsheets: extract cell contents
- [ ] Specs for each format

### Step 8: Article Embedding Service
- [ ] Service to prepare article for chunking (context + body + comments)
- [ ] Generate chunks via ChunkingService
- [ ] Generate embeddings for each chunk
- [ ] Store in Chunk model
- [ ] Background job for async processing
- [ ] Specs

### Step 9: Migrate Questions to Chunks
- [ ] Migration to remove embedding columns from questions
- [ ] Update GenerateQuestionEmbeddingJob to use chunks
- [ ] QuestionChunkingService (title + body + answers + comments)
- [ ] Backfill job to chunk existing questions
- [ ] Specs

### Step 10: Update Search to Use Chunks
- [ ] Update VectorQueryService to query chunks table
- [ ] Update HybridQueryService to work with chunk results
- [ ] Map chunk results back to source documents (articles/questions)
- [ ] Handle ranking/deduplication (multiple chunks from same doc)
- [ ] Show matched chunk/section in search results for context
- [ ] Specs

### Step 11: ArticlePolicy
- [ ] Pundit policy for Article
- [ ] Check publisher/moderator/admin status across attached spaces
- [ ] Specs

### Step 12: Article CRUD Controllers & Views
- [ ] ArticlesController with full CRUD
- [ ] Views: index, show, new, edit, form
- [ ] File upload handling
- [ ] Space attachment/detachment UI
- [ ] Context field for search hints
- [ ] Specs

### Step 13: Comments on Articles
- [ ] Verify Comment polymorphic association works with Article
- [ ] Add comments UI to article show page
- [ ] Re-chunk article when comments change
- [ ] Specs

### Step 14: Admin UI for Publishers
- [ ] Space publishers management (like moderators)
- [ ] Type-ahead user search
- [ ] Specs

### Step 15: Admin Dashboard - Orphaned Articles
- [ ] Add orphaned articles panel/badge to admin dashboard
- [ ] List articles with no space attachments
- [ ] Quick actions to attach or delete orphaned articles
- [ ] Specs

## Future Improvements (Not This Phase)

- [ ] **Draft/Published status** - Articles can be drafts before publishing
- [ ] **Voting on articles** - Maybe useful for community feedback on docs?
- [ ] **Refresh schedule** - Periodic re-fetch of articles from URLs
- [ ] **Version history** - Track changes to articles over time

## Technical Notes

### Vector Index

The chunks table will need an HNSW index similar to what we have for questions:
```sql
CREATE INDEX index_chunks_on_embedding
ON chunks USING hnsw ((embedding::vector(dimensions)) vector_cosine_ops)
```

Index will be created dynamically based on embedding provider dimensions.

### Search Query Changes

Current: Query `questions.embedding`
New: Query `chunks.embedding`, then group/rank by source document

This allows finding the most relevant *part* of a document, not just the most relevant document overall.

### Re-chunking Triggers

Articles need re-chunking when:
- Body changes
- Context changes
- Comments added/edited/deleted

Questions need re-chunking when:
- Title/body changes
- Answers added/edited/deleted
- Comments on question/answers added/edited/deleted

Use background jobs to avoid blocking user actions.
