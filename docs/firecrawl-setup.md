# Firecrawl Setup (Self-hosted Web Scraper)

Firecrawl is a self-hosted web page to markdown service, useful for importing pages behind corporate firewalls.

## Quick Start

```bash
# Start Firecrawl (uses existing Postgres and Valkey)
docker-compose -f docker-compose.dev.yml up -d firecrawl

# Default endpoint: http://firecrawl:3002
# API key for self-hosted: fc-dev (or any value - TEST_API_KEY disables auth)
```

## Architecture

Firecrawl shares our infrastructure:
- **Postgres**: Uses the `nuq` schema for job queuing (see `docker/postgres/firecrawl_init.sql`)
- **Valkey**: Uses database 1 (Rails/Sidekiq use database 0)

## Manual Schema Setup

If your Postgres volume already exists (schema wasn't auto-initialized):

```bash
docker-compose -f docker-compose.dev.yml exec -T postgres psql -U brimming \
  -f /docker-entrypoint-initdb.d/02-firecrawl.sql
```

## Platform Notes

- Image is amd64-only, runs via emulation on Apple Silicon
- The `platform: linux/amd64` is set in docker-compose.dev.yml

## Configuration in Brimming

Admin UI at `/admin/reader_providers`:
- Provider type: `firecrawl`
- Default endpoint: `http://firecrawl:3002`
- API key: `fc-dev` (optional for self-hosted)

Articles store `source_url` and `reader_provider_id` for refresh capability.
