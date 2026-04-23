# ADR 0002: Migrate from SQLite to PostgreSQL

**Date:** 2026-04-22
**Status:** Accepted

## Context

The Moonloop project initially used SQLite3 as the default database for development, test, and production postures. The technology stack relies heavily on Solid Cache, Solid Queue, and Solid Cable to manage background jobs, caching, and WebSockets natively through the database.

As the project approaches readiness for a fully-fledged deployment and operations environment, we need a robust, scalable, and concurrently accessible database system. SQLite, while extremely fast for single-node setups and read-heavy workloads, limits our ability to scale horizontally and leverage advanced distributed tooling effectively without encountering locking contention, especially given the continuous background loads from Solid Queue.

## Decision

We are migrating the entire data layer from SQLite to **PostgreSQL**.
This migration applies across all environments: `development`, `test`, and `production`. 

To achieve this, we decided on the following constraints:
1. **Clean Slate Data:** We will not perform a data migration from the local SQLite databases. We are starting with a clean slate for the data itself.
2. **Strict 1:1 Schema Translation:** We are mapping the existing tables and schema exactly as they were in SQLite into PostgreSQL without immediately introducing any PostgreSQL-specific features (e.g., native JSONB columns where text was used, UUID primary keys). The structure remains identical (with auto-translation of integer keys to bigints by ActiveRecord).
3. **Local Provisioning:** We will utilize Docker (`docker-compose.yml`) to orchestrate the PostgreSQL container locally for development and testing environments, ensuring parity with the eventual deployment environment.

## Consequences

**Positive:**
- Complete parity across environments, eliminating "it works locally" database differences.
- High concurrency support for Solid Queue and Solid Cable.
- Ready for horizontal application scaling in the deployment environment.

**Negative:**
- Developers must run Docker locally to boot the `db` service before running tests or starting the Rails server.
- The `pg` gem replaces `sqlite3`, necessitating the presence of PostgreSQL client libraries on the host machine for native extensions to compile.

## Compliance
This ADR updates the default persistence boundaries outlined in `docs/core/SYSTEM_ARCHITECTURE.md`, firmly establishing PostgreSQL as the system database.
