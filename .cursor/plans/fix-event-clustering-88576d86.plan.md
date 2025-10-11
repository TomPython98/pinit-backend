<!-- 88576d86-1167-4eee-a979-697d1b0e5c51 4377eb28-5094-4b83-837f-24f134bdc050 -->
# Stop Excessive Event Polling and Fix URL Bug

#### What we'll change
- CalendarManager.swift
  - Add a cooldown guard in `fetchEvents()` so it won’t run more than once every 30s unless explicitly forced.
  - Fix the missing slash in `fetchSpecificEvent` URL: change `"\(baseURL)get_study_events/…"` to `"\(baseURL)/get_study_events/…"`.
- ContentView.swift
  - Remove unconditional calls to `calendarManager.fetchEvents()` (two spots found) and replace with a one-time "ensure-initial-load" using a local `@State private var didEnsureInitialEvents = false` guard.
- CalendarView.swift
  - Remove the delayed `fetchEvents()` on RSVP success; rely on WebSocket and local state instead.
- MapBox.swift
  - Remove the delayed `fetchEvents()` after certain actions; rely on WebSocket.
- EventsRefreshView.swift
  - Keep manual refresh only (no auto-refresh on appear).

#### Why this fixes the loop
- After an event delete, some views re-render and currently re-trigger `fetchEvents()` whenever `events` becomes empty or on generic UI transitions. The cooldown + removing unconditional fetch sites stops repeated API calls. WebSocket remains the real-time source of truth.

#### Tests (manual)
- Create → list → delete an event. Confirm:
  - WebSocket deletion removes it locally without triggering a fetch loop.
  - No repeated GET /api/get_study_events/... in server logs.
  - Pull-to-refresh still works via EventsRefreshView.


### To-dos

- [ ] Fix missing slash in fetchSpecificEvent URL in CalendarManager.swift
- [ ] Add 30s cooldown guard to CalendarManager.fetchEvents()
- [ ] Remove unconditional fetchEvents calls from ContentView.swift and guard initial load
- [ ] Remove delayed fetchEvents from CalendarView.swift RSVP flow
- [ ] Remove delayed fetchEvents from MapBox.swift after actions
- [ ] Ensure EventsRefreshView stays manual-only and still works