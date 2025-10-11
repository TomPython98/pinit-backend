<!-- 88576d86-1167-4eee-a979-697d1b0e5c51 11dd3bf8-a36c-464f-9ed5-ef49889873df -->
# Comprehensive Developer Documentation Refresh

#### Deliverable

- One authoritative, developer-focused document that fully reflects the current codebase and deployment, replacing fragmented/obsolete docs.
- Location: `COMPREHENSIVE_TECHNICAL_DOCUMENTATION.md` (repo root).

#### Source of Truth (to review exhaustively)

- Backend: `StudyCon/`, `myapp/` (models, views, urls, routing, consumers, settings, migrations, storage, utils)
- iOS Frontend: `Front_End/Fibbling_BackUp/Fibbling/` (Config, Managers, Views, ViewModels, Utilities, Models)
- Deployment: `Procfile`, `railway.json`, `requirements.txt`, `runtime.txt`
- Existing docs: `/complete_documentation`, `/Documentation`, root readmes

#### Document Structure (high-level)

1. Architecture overview and data flow
2. Backend

- Project layout, settings, env vars
- Database (Postgres via Railway), migrations
- Auth (JWT via SimpleJWT), rate limits, CORS/CSRF
- Models and relationships (incl. `EventReviewReminder` CASCADE)
- REST endpoints (paths, methods, request/response)
- Real-time: Channels, routing, consumers, broadcast utils, message schema
- Storage (R2/S3), static/media handling
- Logging, security considerations

3. iOS Frontend

- App structure (SwiftUI), key managers
- APIConfig (base URLs, endpoints, WebSocket URL)
- Auth/token lifecycle (register/login/save tokens)
- Calendar/events: `CalendarManager`, WebSocket-first updates, 30s cooldown
- Map & clustering behavior, region defaults
- Settings, Notification Preferences (colors/toolbar), Profile/Reviews fixes
- UI/UX patterns (sheets, quick actions wiring, keyboard dismissal)

4. Deployment & Ops

- Railway services, `DATABASE_URL`, `RAILWAY_RUN_COMMAND`
- Healthcheck endpoint, daphne startup, migrations on deploy
- Python 3.13 `psycopg[binary]` version pin

5. Testing & Runbooks

- cURL flows (register/login/create/delete event/account)
- Common errors (401s, migration issues, psycopg import) and fixes

6. Change log (recent critical changes)
7. Glossary

#### Acceptance Criteria

- Every endpoint documented with method, path, auth, payload, response
- WebSocket data contract and flows documented
- All environment variables and deployment steps verified against current code
- iOS flows (auth, event CRUD, real-time updates) matched to code

#### Out-of-Scope

- Android deep dive (keep pointers), future features/speculations

#### Notes

- Obsolete/contradictory content in `complete_documentation` and `Documentation` will be superseded; the new doc will point out deprecations.

#### Timeline (single pass, then refine)

- Pass 1: Full code scan and notes
- Pass 2: Draft full master doc
- Pass 3: Verify endpoints against live server and finalize

### To-dos

- [ ] Read all backend code (models, views, urls, routing, consumers, settings, migrations)
- [ ] Read all iOS Swift code (Config, Managers, Views, ViewModels, Utilities, Models)
- [ ] Review Procfile, railway.json, requirements, runtime, env expectations
- [ ] Review complete_documentation and Documentation to capture/replace content
- [ ] Enumerate endpoints, auth, payloads, responses, errors
- [ ] Document Channels setup, WS URLs, consumers, broadcast utils, message formats
- [ ] Document APIConfig, token lifecycle, CalendarManager cooldown and WebSocket flow
- [ ] Document Railway setup, env vars, migrations, daphne, healthchecks
- [ ] Author COMPREHENSIVE_TECHNICAL_DOCUMENTATION.md end-to-end
- [ ] Cross-check doc vs code/servers and mark deprecated older docs