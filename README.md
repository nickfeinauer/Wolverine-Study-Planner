# Wolverine Study Planner

Student name: **Nick Feinauer**  
UMID: **4014 3770**

A personal academic planner written in Jac 0.37.12. The server, web dashboard,
mobile app and CLI share a persistent graph of courses, deadlines and study
sessions. Add courses and deadlines manually to generate deterministic study plans.
No AI provider key is required.

## Prerequisites and setup

- Jac **0.37.12** on your PATH (`jac --version`).
- Network access for the initial npm dependency installation.
- A modern browser for the web dashboard and mobile browser preview.
- For native mobile: Android SDK/JDK or Xcode and a simulator/device.

From the repository root:

```bash
jac install
jac run
```

Open the URL printed by Jac (normally http://localhost:8000). The API normally
runs at http://localhost:8001, with Swagger at `/docs`. The default app is web.
The first launch installs and compiles the client assets. Subsequent launches reuse the build cache.

## Web

1. Add a course with its name, professor, and semester (professor and semester are optional).
2. Select the course, enter a title and due date, and choose the deadline type.
3. Difficulty is 1–5. Hours of 0 use the deterministic recommendation;
   positive hours specify the total directly. At difficulty 3, default totals are
   30 minutes for homework/quiz/other, 90 minutes for projects, 60 minutes for
   exams, and 120 minutes for finals. New sessions are at most 30 minutes.
4. Saving a deadline generates study sessions automatically.
5. Complete sessions or assignments and refresh to see changes made elsewhere.
   Completing an assignment also completes its remaining sessions.
6. **Delete class** asks for confirmation, then removes the class and all of its
   deadlines and study sessions.


Past or same-day deadlines remain visible but produce no future study sessions.
Upcoming sessions and the daily total use America/Detroit dates. Data survives
refreshes and server restarts in `.jac/data`; do not delete that directory if you
want to retain your planner. No demo courses are loaded automatically.

## CLI

Keep `jac run` running in one terminal and use another terminal:

```bash
jac run cli/main.jac today
jac run cli/main.jac courses
jac run cli/main.jac assignments
jac run cli/main.jac add course --code "EECS 445" --name "Machine Learning" --semester "Fall 2026"
# Copy the course ID printed above:
jac run cli/main.jac add assignment --course COURSE_ID --title "Midterm" --due 2026-10-15 --type exam --difficulty 3
jac run cli/main.jac study
jac run cli/main.jac study ASSIGNMENT_ID
jac run cli/main.jac complete SESSION_ID --session
jac run cli/main.jac complete ASSIGNMENT_ID
```

`study ASSIGNMENT_ID` replans remaining study time from today, preserving completed
sessions and subtracting their minutes from the total estimate.  `courses`, `assignments` and `study` print IDs for update commands.
The CLI calls the running planner service over HTTP; it does not use a second
local database. Default: `http://127.0.0.1:8001`, route `/api/planner`.
Override `JAC_APP_PLANNER_URL` and optionally `JAC_APP_PLANNER_ROUTE` for a remote
server or a different API port.

## Mobile

The mobile app uses real `@jac/mobui` components and the same backend as web.
It supports adding courses with name/professor/semester, deleting classes with
confirmation, adding deadlines with course/type/difficulty/estimated hours,
viewing today's and upcoming study sessions, daily totals, refresh, and
completing sessions or assignments. Enter mobile due dates as `YYYY-MM-DD`.
Course, deadline-type and difficulty choices use tappable buttons.

For the browser preview in Jac 0.37.12, stop the web dev server first, then:

```bash
jac build mobile --platform web
jac run --dev --platform web mobile
```

The explicit build is required on this version to create the mobile preview's
entry asset. Jac serves the same planner service and persistent graph. Do not
run web and mobile Vite previews simultaneously in this checkout: they share
`.jac/client` launch configuration. Restart `jac run` to return to web.

To run the website and mobile browser preview together, build mobile before
starting the website:

```bash
jac build mobile --platform web
jac run
```

In a second terminal:

```bash
python scripts/mobile_preview.py
```

Website: http://localhost:8000. Mobile: http://localhost:8010. Both use the
website's backend at port 8001 and the same planner data. Refresh either app to
see changes from the other. This serves the built mobile app; rebuild mobile and
reload its page after changing mobile source.

For native development:

```bash
jac setup mobile
jac run --dev mobile
# Production device builds:
jac build mobile --platform android
jac build mobile --platform ios
```

Follow the host/device URL printed by Jac. A physical device needs to reach the
backend over the network. Native builds require the corresponding platform SDK.
Browser preview verification does not substitute for a native-device test.

## Shared architecture

- `core/planner/data.jac`: the `[apps.planner]` Jac service. Persistent graph:
  `root.shared -> Course -> Assignment -> StudySession`. It owns validation,
  creation, reads, updates, completion and session generation.
- `core/planner/scheduler.jac`: effort-based scheduling over up to 28 days before
  the deadline. Entered hours override type/difficulty defaults. Exact minute
  totals are conserved, with a modest increase near the deadline and blocks of
  at most 30 minutes. Short deadlines can still require multiple blocks per day.
- `core/site/planner/PlannerHome.jac`: web dashboard.
- `core/site/planner/PlannerMobile.jac`: mobile daily planner.
- `cli/main.jac`: terminal client of the same service.

`jac run` colocates the planner service with the web server. Jac generates the
HTTP APIs and typed client bridges. There is one planner for this local personal
app; it does not implement separate authenticated student accounts.

Backend update functions support course details and assignment edits before
any study sessions are completed. Rescheduling rejects assignments with completed study sessions to preserve
study history. The MVP interfaces expose creation and completion.

## Validation

```bash
jac check core/planner/data.jac core/planner/scheduler.jac
jac check web/main.jac cli/main.jac mobile/main.jac
jac test cli/main.test.jac core/planner/data.test.jac
```

The scheduler tests check conserved study minutes, increasing weights, and no
sessions for past/same-day deadlines. Jac's generated JSX may report lint warnings;
all modified files must pass compilation. See `VALIDATION.md` for exercised
end-to-end checks and remaining submission checks.

What makes this project distinctive: effort-based study recommendations, reliable
planning independent of AI, persistent graph relationships, and
four connected components written in one language.

The original `jac create --awesome` example source remains in the workspace.
Its unused web routes are parked in `web/examples/pages` and excluded by
`.jacignore`; unused social/scoring services are deactivated. The original
README is preserved in `README.generated.md`, and the previous app configuration
is in `jac.examples.toml`. The active web routes and service belong to the planner.
