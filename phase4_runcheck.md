# Phase 4 — Manual Run Checklist (Runbook)

This checklist leads you from backup → cleanup → seed → verify → enable automation.

## PREPARATION
1. Ensure you have repo access and the following CLIs installed: `gh`, `psql` or `pg_dump` (Postgres client), and `git`.
2. Ensure `.env` at repo root contains SUPABASE_DB_URL (or you will export it manually).
3. Notify the team: disable the scheduled sync (see step 1) so automation won't run mid-cleanup.

## 0. Disable automation (prevent concurrent writes)
- Via GitHub UI: Actions → Sync Royalties → Disable workflow
- Or CLI: `gh workflow disable sync.yml --repo <OWNER/REPO>`

## 1. Backup Supabase data (critical)
```bash
export SUPABASE_DB_URL="$SUPABASE_DB_URL"
pg_dump --data-only "$SUPABASE_DB_URL" > backup_prephase4_data.sql