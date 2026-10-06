# AGENTS.md

## Project Overview

This project is a **Personal Academic Planning App built in Jac**.

The main idea is a **Syllabus Study Planner** that lets a student upload an image or screenshot of a course syllabus, extract course information and deadlines, store them in a shared planner, and automatically generate recommended study sessions before assignments, quizzes, projects, and exams.

The app must satisfy the Assignment 1 requirement of having four connected components:

1. **Server**
2. **Web frontend**
3. **Mobile app**
4. **CLI**

All four components should share the same planning data and backend logic whenever possible.

The project should run from the repository root with:

```bash
jac run
```

The default application should remain the web application unless there is a strong reason to change it.

---

## Primary User Goal

A student should be able to:

1. Upload a syllabus image or screenshot.
2. Extract the course name/code and important deadlines.
3. Review and correct the extracted information before saving.
4. Save assignments, exams, quizzes, and projects.
5. Automatically generate recommended study sessions before each due date.
6. View upcoming deadlines and recommended study sessions.
7. Mark assignments and study sessions complete.
8. Access useful planner actions from the web, mobile app, and CLI.

The application should feel like an academic planner rather than a generic to-do list.

---

## Core MVP

Prioritize a reliable working MVP before adding extra-credit features.

The MVP should include:

### Server

- Persistent courses
- Persistent assignments/deadlines
- Persistent study sessions
- Functions for creating, reading, updating, and completing planner items
- Study-session generation logic
- Shared backend functionality for web, mobile, and CLI

### Web

The web interface is the primary planner interface.

It should support:

- Viewing courses
- Viewing upcoming deadlines
- Viewing recommended study sessions
- Adding a course manually
- Adding an assignment manually
- Marking assignments complete
- Uploading a syllabus image
- Reviewing extracted syllabus data before saving
- Loading or refreshing planner data from the shared backend

### Mobile

Keep mobile simpler than web.

It should support useful daily planning actions such as:

- Today's study sessions
- Upcoming deadlines
- Marking a study session complete
- Marking an assignment complete

Mobile should use the same backend data as the web application.

### CLI

The CLI should provide practical terminal workflows.

Useful commands include:

```text
today
courses
assignments
add
complete
study
```

Examples of expected behavior:

```bash
jac run cli/main.jac today
```

should show today's study schedule and upcoming deadlines.

The exact command structure may follow the patterns already used in the generated Jac example project.

---

## Core Data Model

Prefer a graph-oriented Jac data model.

### Course

Suggested fields:

```text
code
name
professor
semester
```

Example:

```text
EECS 445
Machine Learning
```

### Assignment

Suggested fields:

```text
title
due_date
assignment_type
difficulty
estimated_hours
completed
```

Supported assignment types should include at least:

```text
homework
project
quiz
exam
final
other
```

### StudySession

Suggested fields:

```text
date
duration_minutes
description
completed
```

### Suggested Relationships

Conceptually:

```text
root
 └── Course
      └── Assignment
           └── StudySession
```

Course, Assignment, and StudySession data should persist between sessions.

---

## Study Recommendation Logic

Recommended study times should not depend entirely on an LLM.

Use deterministic scheduling logic so the feature remains reliable even if AI is unavailable.

Suggested baseline total study times:

| Type | Suggested Hours |
| --- | ---: |
| Homework | 2-4 |
| Quiz | 2-3 |
| Project | 5-10 |
| Exam | 6-10 |
| Final | 10-15 |

Difficulty can modify the baseline.

Suggested multipliers:

```text
difficulty 1 -> 0.70
difficulty 2 -> 0.85
difficulty 3 -> 1.00
difficulty 4 -> 1.25
difficulty 5 -> 1.50
```

Distribute study time across the days before the due date.

Prefer slightly more study time closer to the deadline.

Example:

```text
EECS 445 Midterm
Due: October 15
Recommended: 7 hours

Oct 10 - 60 min
Oct 11 - 60 min
Oct 12 - 90 min
Oct 13 - 120 min
Oct 14 - 150 min
```

Avoid scheduling study sessions after the assignment due date.

---

## Syllabus Image Feature

This is the main distinguishing feature of the project.

The intended workflow is:

```text
Upload syllabus image
        ↓
Extract syllabus information
        ↓
Show review screen
        ↓
User edits/confirms results
        ↓
Save course and deadlines
        ↓
Generate study sessions
```

### Extracted Information

Try to extract:

- Course code
- Course name
- Professor/instructor when available
- Assignments
- Homework
- Projects
- Quizzes
- Midterms
- Final exam
- Due dates or exam dates

### Important AI Rule

Do **not** invent a due date when the syllabus does not clearly provide one.

If a date cannot be determined, leave it blank or flag the item for review.

### Review Before Saving

Do not automatically commit AI-extracted information.

The user should be able to review something like:

```text
Course:
EECS 445 - Machine Learning

Detected items:

[x] Homework 3    2026-10-08
[x] Midterm       2026-10-15
[x] Project 2     2026-11-03

Edit / Confirm
```

Only save the data after user confirmation.

---

## AI Integration

Use Jac-native AI capabilities when practical.

If using `by llm()`:

- Prefer structured typed results.
- Avoid parsing free-form AI prose when a typed object can be returned.
- Keep extraction logic separate from planner persistence logic.
- Do not make the entire application dependent on an external AI provider.
- Manual course and assignment entry must continue to work when AI is unavailable.

Suggested conceptual result types:

```text
SyllabusItem
    title
    date
    item_type

SyllabusResult
    course_name
    course_code
    professor
    assignments
```

Because this project uses Jac 0.37.x, follow syntax already present in this repository and course-provided examples rather than assuming syntax from a newer Jac release.

---

## Web Design

The planner should have a simple academic dashboard.

A useful layout is:

```text
------------------------------------------------------
Wolverine Study Planner
------------------------------------------------------

Classes        Open Deadlines        Study Sessions

Upcoming Deadlines
------------------------------------------------------
EECS 445    Homework 3       Oct 8
STATS 413   Homework 5       Oct 9
EECS 445    Midterm          Oct 15

Today's Study Plan
------------------------------------------------------
EECS 445    Homework 3       60 min
STATS 413   Homework 5       45 min

Add Course / Assignment

Upload Syllabus
[ Choose Image ]
[ Analyze Syllabus ]
------------------------------------------------------
```

Prioritize clarity and reliability over complicated visual effects.

---

## Extra Credit Priorities

Once the MVP works, extra-credit improvements should be added roughly in this order:

1. Reliable syllabus image extraction
2. Editable extraction-review screen
3. Smart study-session generation
4. Calendar-style deadline view
5. Course progress indicators
6. Daily study-time totals
7. Exam-specific study plans
8. AI-generated study suggestions
9. Google Calendar integration
10. Notifications or reminders

Do not sacrifice basic functionality to add extra-credit features.

---

## Jac Project Structure

This repository started from:

```bash
jac create --awesome
```

Reuse patterns from that generated project.

Likely planner-specific organization:

```text
core/
  planner/
    data.jac
    scheduler.jac
    syllabus.jac

  site/
    planner/
      PlannerHome.jac

web/
  main.jac

mobile/
  main.jac

cli/
  main.jac
```

It is acceptable to use a slightly different structure when it better matches the existing generated workspace.

Do not unnecessarily delete the generated Jac example files unless they interfere with the planner.

---

## Jac Version Compatibility

The development environment uses **Jac 0.37.x**.

Important rules:

- Prefer syntax found in this repository.
- Prefer syntax found in the Assignment 1 course resources.
- Do not blindly copy syntax from the newest Jac documentation.
- Run `jac check` on modified Jac files when possible.
- Test `jac run` after meaningful changes.

For JSX event handlers, use valid Jac lambda syntax such as:

```jac
onChange={lambda (e) { value = e.target.value; }}
```

instead of:

```jac
onChange={lambda e { value = e.target.value; }}
```

---

## Development Priorities

When making changes, use this priority order:

1. Project compiles.
2. `jac run` launches successfully.
3. Server persistence works.
4. Web planner works.
5. Shared backend works from CLI.
6. Shared backend works from mobile.
7. Syllabus extraction works.
8. UI polish and extra credit.

Do not introduce a large redesign while basic compilation or persistence is broken.

---

## Testing Checklist

Before considering a feature complete, verify:

### Web

- `jac run` succeeds.
- Planner page loads.
- Course can be added.
- Assignment can be added.
- Assignment remains after refresh/restart when persistence is expected.
- Study sessions are generated.
- Assignment can be marked complete.

### Syllabus

- Image can be selected.
- Analysis produces structured items.
- User can review items.
- User can edit incorrect data.
- Confirming creates the course and deadlines.
- Study sessions are generated afterward.

### Mobile

- Mobile component launches using documented steps.
- It reads the same planner data.
- At least one useful update action works.

### CLI

- CLI launches.
- At least one read action works.
- At least one write/update action works.
- Changes are visible in the web app.

---

## README Requirements

The root `README.md` must eventually include:

- Student name
- UMID
- Project description
- Main features
- Prerequisites
- Setup instructions
- `jac run` instructions
- Web instructions
- Mobile instructions
- CLI instructions
- Explanation of shared architecture
- Explanation of what makes the project impressive

Before submission, README instructions should be tested from a fresh checkout.

---

## Git and Repository Rules

The final project will be submitted as a GitHub repository.

Do not commit:

- API keys
- passwords
- `.env` secrets
- virtual environments
- unnecessary build artifacts
- large temporary files

Use environment variables for AI/API credentials.

Make commits that describe meaningful milestones, for example:

```text
Add persistent planner data model
Build planner dashboard
Add study session generator
Add mobile daily plan
Add CLI planner commands
Add syllabus extraction workflow
```

---

## Code Quality Expectations

When modifying the project:

- Keep functions focused.
- Reuse shared backend logic instead of duplicating it.
- Avoid hardcoding demo course data into production logic.
- Keep AI extraction separate from persistence.
- Keep study scheduling deterministic where practical.
- Handle empty planner states gracefully.
- Validate required fields.
- Do not crash when a syllabus extraction returns incomplete information.
- Preserve working functionality when adding new features.

---

## Definition of Done

The project is ready to submit when:

```text
jac run
```

successfully starts the web application and server from the repository root, and the following end-to-end workflow works:

```text
Create or import a course
        ↓
Add/extract a deadline
        ↓
Persist deadline
        ↓
Generate recommended study sessions
        ↓
View them on web
        ↓
View useful shared data on mobile
        ↓
View/use useful shared data from CLI
        ↓
Mark work complete
```

The final product should clearly demonstrate that the server, web frontend, mobile app, and CLI are parts of the same academic planning system.
