# microCMS Backup — `annien.microcms.io`

Export date: 2026-10-05
Source service: https://annien.microcms.io/
Exported by: Claude Code (pre-restructure snapshot)

## Current APIs (5/5 quota)
| endpoint | type | belongs to |
|---|---|---|
| holidays | list | An Nien (created 2026-10-05, 12 seeded items) |
| app-config | object | LovelyMusic config_json |
| app-config-develop | object | LovelyMusic config_json (dev) |
| config | object | LovelyMusic flat fields (prod) |
| config-develop | object | LovelyMusic flat fields (dev) |

## Target schema (An Nien)
- `holidays` (list) — keep, 12 items
- `cultural_articles` (list) — create, schema from CulturalArticle DTO
- `app-update` (object) — create, schema from iletai/AppUpdateKit

Quota note: free plan = 5 APIs. Deleting 4 LovelyMusic APIs frees room for the 2 new ones.
