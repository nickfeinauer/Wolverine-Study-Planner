# MVP validation

Validated on macOS with Jac **0.37.12**, October 5, 2026.

## Compilation and automated tests

- `jac check` passed for all 12 modified/new MVP source files: backend,
  scheduler, web dashboard, CLI and mobile (original MVP validation).
- `jac test cli/main.test.jac core/planner/data.test.jac`: **4 tests passed**.
- Backend tests use `JacTestClient` with separate temporary storage paths.
- Tests cover total study minutes, increasing study weights, deadline bounds,
  same-day/past deadlines, graph creation, idempotent generation, completion
  cascade and omitted numeric API defaults.

Jac reports generated JSX lint warnings (such as unused implicit setters and
HTML tag name resolution) but no compilation errors in the MVP files.

## Web and persistence

Chrome browser automation exercised:

- Root `jac run` launch and dashboard loading.
- Add course and assignment through the web forms.
- Automatic study generation and today's minute total.
- Browser refresh and a full server restart retain the assignment and sessions.
- Mark a session complete, then mark an assignment complete.
- CLI-created records appear in web; web-created records appear in CLI.
- Mobile-created completion remains visible after returning to the web app.

## CLI

Executed `courses`, `add course`, `add assignment`, `assignments`, `today`,
`study` and `complete` against the running server. CLI routing defaults to
`http://127.0.0.1:8001/api/planner`; the CLI does not open a separate planner DB.

## Mobile

`jac check mobile/main.jac` passed. `jac build mobile --platform web` succeeded.
`jac run --dev --platform web mobile` launched the browser preview after that
explicit build. Chrome displayed a CLI-created deadline and today's 60-minute
session. Clicking **Complete session** removed it from today's plan, retained
the open assignment, and persisted the completion. The final mobile build
also completed an assignment successfully after the clean-build configuration
fix.

Jac 0.37.12 needs the explicit mobile web build to create the preview entry
asset. Web and mobile preview processes share generated launch configuration,
so use one Vite preview at a time in this checkout.

Android/iOS device launches have **not** been tested; browser preview is the
verified mobile target. Native launch instructions are in README.md.

## Clean setup

Copied source to a temporary directory with no `.jac` build cache or database.
`jac install` installed dependencies, and
`jac run --port 8020 --api-port 8021` launched successfully. The same Chrome
workflow passed there for the original MVP.

The clean-install check exposed unrelated generated example routes pulling
Python provider dependency code into the client compiler. Parking those routes,
deactivating unused example services resolved the failure; no generated example source was deleted.

## Repository

The provided directory has no `.git` repository, so there is no real checkout
or commit to validate. `.gitignore` excludes generated clients, persistent
storage, environments, secrets and temporary build output. The original example
source remains, with unused routes parked under web/examples/pages and their
services disabled. Its README is preserved in README.generated.md and its
previous app configuration in jac.examples.toml.

Verification records created through the UI/CLI remain only in the ignored
local `.jac/data` planner, never hardcoded in application source.

## Current planner update

Syllabus upload, extraction, import endpoints and provider configuration have
been removed at the user's request. The scheduler now starts today, allocates
roughly one hour per study day over at most 28 days, modestly increases daily
work near the end, and splits days into blocks no longer than 90 minutes.
Replanning preserves completed sessions and deducts their minutes from the estimate.
Automated tests cover short efforts, large efforts, rushed deadlines, exact totals,
difficulty defaults, explicit-hour overrides and completed-time credit.

Current update verification: `jac check` passed all six active backend/client
entry files (existing JSX lint warnings remain); `jac test -j 0
cli/main.test.jac core/planner/data.test.jac` passed all six tests.
`jac run --port 8020 --api-port 8021` launched successfully. Chrome confirmed
there is no file-upload input, created a course and a 0.5-hour deadline,
verified its 30-minute session, replanned it, and completed it successfully.

Class deletion and replan follow-up: both changed Jac files passed `jac check`;
all eight scheduler/API tests passed. `jac run --port 8030 --api-port 8031`
launched successfully. Chrome verified replan success feedback, canceling a
class deletion, confirming cascade deletion, and absence of its deadline after
refresh. Replanning a deadline today or overdue now fails explicitly before
removing any sessions; completed minutes remain credited for future deadlines.

Shorter recommendation update: removed the web replan action; default effort is
30 minutes for homework/quiz/other, 90 for projects, 60 for exams, and 120 for
finals at difficulty 3. New session blocks are capped at 30 minutes. Explicit
hours still override the total. Existing stored schedules are unchanged.
Jac compilation checks passed; all eight automated tests passed; the app
launched on ports 8050/8051. Chrome verified the replan button is absent and a
new default homework deadline produces a 30-minute study session.

Mobile feature parity update: `jac check` passed the mobile component and entry
file. `jac build mobile --platform web` and `jac run --dev --platform web mobile`
succeeded. Chrome at a 390×844 viewport exercised course creation, deadline
creation with type/difficulty/custom hours, refresh persistence, session and
assignment completion, deletion cancellation and confirmed cascade deletion.
Shared API reads verified each resulting mutation and the exact 30-minute total.
Native Android/iOS device testing remains outstanding.

Mobile save usability follow-up: Jac checks, mobile build and preview launch
passed. Chrome verified missing-field messages beside the save buttons and the
complete creation/completion/deletion workflow with both mouse clicks and touch
taps at a 390×844 viewport. Save controls now report saving state and validation
errors locally instead of silently disabling for missing fields; one existing
course is selected automatically. No transport failure was reproduced in the
running browser preview.
