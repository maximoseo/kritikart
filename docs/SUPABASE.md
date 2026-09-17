# Supabase — KritiKart Leaderboards

## Project

- **Host project**: `game-asset-hub` (existing, free tier — no new spend)
- **Ref**: `jdpxvwihlmpmmmiihvws` · Region: eu-central-1 · Postgres 17
- **Dashboard**: https://supabase.com/dashboard/project/jdpxvwihlmpmmmiihvws
- Credentials live in `/root/.env.secrets`: `KRITIKART_SUPABASE_URL`,
  `KRITIKART_SUPABASE_ANON_KEY` (anon key is client-public by design; it ships
  inside the game binary).

## Schema — `public.kritikart_leaderboard`

| column | type | constraints |
|---|---|---|
| id | bigint identity | PK |
| player_name | text | 1–24 chars, not null |
| track | text | default 'storm_coast' |
| difficulty | text | easy / medium / hard |
| best_lap_ms | bigint | nullable, > 0 |
| total_time_ms | bigint | not null, > 0 |
| created_at | timestamptz | default now() |

Index: `(track, difficulty, total_time_ms asc)` for fast top-N queries.

## Row Level Security (verified live 2026-09-17)

| policy | grant | effect |
|---|---|---|
| `kk_read` | SELECT to anon/authenticated | anyone can read |
| `kk_insert` | INSERT to anon/authenticated | anyone can post a score |
| — | UPDATE / DELETE | **blocked** (verified: PATCH affects 0 rows) |

## REST API

```bash
# post a score
curl -X POST "https://jdpxvwihlmpmmmiihvws.supabase.co/rest/v1/kritikart_leaderboard" \
  -H "apikey: $ANON" -H "Authorization: Bearer $ANON" -H "Content-Type: application/json" \
  -d '{"player_name":"Racer1","track":"storm_coast","difficulty":"medium","total_time_ms":138500}'

# top 10
curl "https://jdpxvwihlmpmmmiihvws.supabase.co/rest/v1/kritikart_leaderboard?select=player_name,total_time_ms&order=total_time_ms.asc&limit=10" \
  -H "apikey: $ANON" -H "Authorization: Bearer $ANON"
```

## Game integration

`scripts/game/leaderboards.gd` (autoload `Leaderboards`):
- listens for any `RaceManager` entering the scene tree, auto-submits the player's
  result on `race_finished`
- disabled in headless/editor unless `KRITIKART_ALLOW_EDITOR_SUBMIT=1`
- env override: `KRITIKART_SUPABASE_URL` / `KRITIKART_SUPABASE_ANON_KEY`
- `fetch_top(track, difficulty, limit, cb)` available for a leaderboard UI
- offline-first: fire-and-forget, gameplay never blocks on network

## Moving to a dedicated project (if ever needed)

A new Supabase project costs $10/mo (verified via API on 2026-09-17). To migrate:
re-run the DDL from this file in the new project, update the two env vars and the
`DEFAULT_*` constants in `leaderboards.gd`.
