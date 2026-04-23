# Task: Migrate to PostgreSQL

## Task Description
Migrate the data layer to **PostgreSQL**.
- Update database adapter and `database.yml`.
- Adapt migrations and schema.
- Align job queue / cache (Solid Queue, Solid Cache, Solid Cable) to run on Postgres.
- Plan data migration from SQLite if applicable.
- Dependencies: Deployment and ops environment; current stack REQ-PLAT-001 (SQLite development).

## Domain Model
_No new domain entities introduced. This is purely an infrastructure and platform migration._

## Scratchpad / Architect Notes
- **Solid Stack**: The project currently relies on `solid_cache`, `solid_queue`, and `solid_cable`. Moving to PostgreSQL means they will now be backed by PostgreSQL.
- **Data Migration**: We are starting with a **clean slate** (base limpia). No data migration from SQLite is required.
- **Local Dev**: We are migrating **everything to PostgreSQL**, including local development and test environments. A `docker-compose.yml` will be added.
- **Schema**: We are doing a **strict 1:1 translation** of the current schema, without introducing new PG-specific features for now.

<implementation_plan>
  <step id="1" status="complete">
    <type>Baseline</type>
    <description>Run existing tests to establish a green baseline. (Note: Since we are replacing the database adapter, we will execute the test suite right after configuring PG to ensure parity and fix any adapter incompatibilities).</description>
  </step>
  <step id="2" status="complete">
    <type>Environment Setup</type>
    <description>Create a `docker-compose.yml` to provision PostgreSQL for local `development` and `test` environments.</description>
  </step>
  <step id="3" status="complete">
    <type>Dependencies</type>
    <description>Update `Gemfile` to remove `sqlite3` and add the `pg` gem. Run `bundle install`.</description>
  </step>
  <step id="4" status="complete">
    <type>Configuration</type>
    <description>Update `config/database.yml` to use the `postgresql` adapter for all environments. Set up proper connection strings pointing to the local Docker container.</description>
  </step>
  <step id="5" status="complete">
    <type>Schema Migration</type>
    <description>Execute `rails db:drop db:create db:migrate` on PostgreSQL. Identify and resolve any SQLite-specific constraints or indices in `db/migrate/*.rb`. Generate the new `db/schema.rb`.</description>
  </step>
  <step id="6" status="complete">
    <type>Documentation</type>
    <description>Update `docs/core/SYSTEM_ARCHITECTURE.md` and `docs/ROADMAP.md` to officially document PostgreSQL as the system database.</description>
  </step>
</implementation_plan>
