# Target Schema — An Nien on `annien.microcms.io`

Design date: 2026-10-05
Package contract: [iletai/AppUpdateKit](https://github.com/iletai/AppUpdateKit) v1.1.0
App code contract: `MicroCMSHolidayDTO` (`HybridHolidayRepository.swift`), `CulturalArticle` (`VNCalendarDomain`)

## Principles

1. **One domain, one purpose** — `annien.microcms.io` serves An Nien only. LovelyMusic configs move out or stay on their own service.
2. **DTO-first** — every field exists because app code decodes it. No speculative fields.
3. **AppUpdateKit native** — update gating uses the official package schema, not a home-grown remote config.
4. **Offline-first preserved** — `holidays` keeps bundled JSON fallback; missing key or network error never blocks launch.

## APIs

### 1. `holidays` (list) — EXISTS, seeded 12

| fieldId | kind | required | matches DTO |
|---|---|---|---|
| title | text | yes | `title` |
| calendarType | select `lunar` / `solar` | yes | `calendarType` (decoded as String; select returns array — client unwraps) |
| day | number | yes | `day` |
| month | number | yes | `month` |
| isNationalHoliday | boolean | no (default false) | `isNationalHoliday` |
| isTraditionHoliday | boolean | no (default false) | `isTraditionHoliday` |
| summary | textArea | yes | `summary` |
| customs | textArea | no | `customs` |
| taboos | textArea | no | `taboos` |
| rituals | textArea | no | `rituals` |

`updatedAt` comes from microCMS system timestamp — no custom field.

### 2. `cultural_articles` (list) — TO CREATE (quota blocked)

| fieldId | kind | required | matches DTO |
|---|---|---|---|
| title | text | yes | `title` |
| slug | text (unique) | yes | `slug` |
| coverImageURL | text (URL) | no | `coverImageURL` |
| contentHTML | textArea | yes | `contentHTML` |
| category | select `tet` / `le_hoi` / `phong_tuc` / `am_thuc` | yes | `category` |

Note: doc `07-microcms-and-offline-content.md` describes `coverImage.url` object + `content` — **code wins**, fields are flat strings as decoded by `CulturalArticle`.

### 3. `app-update` (object) — TO CREATE — AppUpdateKit contract

Single-object API. Field IDs must match exactly what `AppUpdateFetcher.microCMS(endpoint:apiKey:)` decodes:

| fieldId | kind | required | AppUpdateKit role |
|---|---|---|---|
| minimum_version | text | yes | below this → `.forceUpdate` |
| latest_version | text | yes | below this → `.optionalUpdate` |
| store_url | text | yes | App Store / TestFlight URL |
| is_maintenance | boolean | no (default false) | true → `.maintenance` |
| title | text | no | dialog title |
| message | textArea | no | dialog body |
| release_notes | textArea | no | optional-update notes |

Semver vector compare: `"1.2" == "1.2.0" == "1.2.0.0"`. Fail-safe: any fetch error → `.none`.

Initial values (from current app):

```json
{
  "minimum_version": "1.0.0",
  "latest_version": "1.0.0",
  "store_url": "https://apps.apple.com/app/id<ANNIEN-APP-ID>",
  "is_maintenance": false,
  "title": "Cập nhật An Niên",
  "message": "Phiên bản mới đã sẵn sàng. Vui lòng cập nhật để tiếp tục.",
  "release_notes": ""
}
```

## Quota plan

Free plan: 5 APIs. Currently 5/5 (1 An Nien + 4 LovelyMusic).

| Step | Action | Net quota |
|---|---|---|
| 1 | Delete `app-config`, `app-config-develop`, `config`, `config-develop` | 5 → 1 |
| 2 | Create `cultural_articles` | 1 → 2 |
| 3 | Create `app-update` | 2 → 3 |

Deleting LovelyMusic APIs is destructive — requires explicit user confirmation. Backups in this folder capture field schemas + config_json content before deletion.

## App integration (follow-up, after CMS ready)

1. `project.yml` — add `iletai/AppUpdateKit` to AnNien target.
2. New `App/Infrastructure/Update/AppUpdateService.swift` — wrap `AppUpdateChecker.check`.
3. `AnNienApp` — run check on launch + foreground; route `.forceUpdate` / `.maintenance` to blocking UI.
4. API key via `Secrets.xcconfig` (`MICROCMS_API_KEY`) — same GET-only key as holidays.
5. Endpoint constant `app-update` next to existing `MicroCMSServiceDomain = "annien"`.
