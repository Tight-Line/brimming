# Technical Debt

## PostgreSQL Client / pg_dump / Migrations Mess

**Status:** Needs cleanup

**Problem:** Fragile, inconsistent setup for PostgreSQL tooling across different environments:

1. **CI (GitHub Actions):** Uses `psql` to load `structure.sql` directly, bypassing Rails migrations entirely to avoid `pg_dump` version mismatch (runner has pg_dump 16, container runs PG 17)

2. **Docker production image:** Uses Debian's default postgresql-client (v15) because the PGDG repo's PG17 client has broken dependencies (`libldap-2.5-0` not available in bookworm-slim)

3. **structure.sql post-processing:** `lib/tasks/db_structure_fix.rake` patches `structure.sql` after every migration to:
   - Add `IF NOT EXISTS` to schema/extension statements
   - Re-add `CREATE EXTENSION` for vector/pg_trgm if pg_dump omits them
   - This runs automatically after `db:migrate` and `db:schema:dump`

4. **Extension schema:** Extensions live in `public` schema (not `brimming`) for portability, but types must be qualified as `public.vector` in structure.sql because pg_dump clears the search_path

**Risks:**
- CI doesn't actually test migrations, only schema loading
- Version mismatches between environments could cause subtle bugs
- The rake task is a band-aid that may break with future Rails/PG versions

**Ideal Solution:**
- Pin all environments to the same PostgreSQL major version
- Use a Docker image with matching pg_dump version in CI
- Or: switch to `schema.rb` format (loses some PG-specific features)
- Or: use a proper multi-stage CI that runs migrations in a container
