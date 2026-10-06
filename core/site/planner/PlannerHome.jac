import from core.planner.data { PlannerData, planner_data, add_course, add_assignment, complete_assignment, complete_session, delete_course }

def:pub PlannerHome -> JsxElement {
    has data: PlannerData | None = None, error: str = "", busy: bool = False, notice: str = "", deleting: str = "",
        name: str = "", professor: str = "", semester: str = "",
        courseId: str = "", title: str = "", due: str = "", kind: str = "homework", difficulty: int = 3, hours: float = 0.0;
    async def refresh -> None {
        try { data = await planner_data(); error = ""; }
        except Exception as e { error = str(e); }
    }
    can with entry { refresh(); }
    async def saveCourse -> None {
        busy = True;
        try {
            course = await add_course(name, name, professor, semester);
            courseId = course.id; name = ""; professor = ""; semester = "";
            await refresh();
        } except Exception as e { error = str(e); }
        busy = False;
    }
    async def saveAssignment -> None {
        busy = True;
        try {
            await add_assignment(courseId, title, due, kind, difficulty, hours);
            title = ""; due = ""; await refresh();
        } except Exception as e { error = str(e); }
        busy = False;
    }
    async def removeCourse(id: str) -> None {
        busy = True; notice = "";
        try {
            await delete_course(id);
            if courseId == id { courseId = ""; }
            deleting = "";
            await refresh();
            notice = "Class and its deadlines and study sessions deleted.";
        } except Exception as e { error = str(e); }
        busy = False;
    }
    async def finish(id: str, session: bool) -> None {
        busy = True;
        try {
            if session { await complete_session(id); } else { await complete_assignment(id); }
            await refresh();
        } except Exception as e { error = str(e); }
        busy = False;
    }
    if data is None { return <main className="p-6"><h1>Wolverine Study Planner</h1><p>{error or "Loading planner…"}</p><button onClick={lambda { refresh(); }}>Retry</button></main>; }
    openAssignments = [a for a in data.assignments if not a.completed];
    openSessions = [s for s in data.sessions if not s.completed and s.date >= data.today];
    daily = [s for s in openSessions if s.date == data.today];
    return <main className="mx-auto max-w-5xl p-6 space-y-6">
        <header className="rounded-xl bg-slate-900 text-white p-6">
            <h1 className="text-3xl font-bold">Wolverine Study Planner</h1>
            <p>Plan your deadlines. Make time to learn.</p>
            <button className="mt-3 border rounded px-3 py-1" onClick={lambda { refresh(); }}>Refresh planner</button>
        </header>
        {if error { <p role="alert" className="text-red-700">{error}</p> }}
        {if notice { <p role="status">{notice}</p> }}
        <div className="grid grid-cols-3 gap-4">
            <p>{str(len(data.courses)) + " classes"}</p><p>{str(len(openAssignments)) + " open deadlines"}</p><p>{str(sum([s.duration_minutes for s in daily])) + " study minutes today"}</p>
        </div>
        <section><h2 className="text-xl font-bold">Classes</h2>
            {if not data.courses { <p>Add your first course below.</p> }}
            {for c in data.courses { <div key={c.id} className="flex justify-between border-b py-3 gap-3">
                <span>{c.name + " · " + c.professor + " · " + c.semester}</span>
                {if deleting == c.id { <div><p>Delete this class and all its deadlines and study sessions?</p><button disabled={busy} onClick={lambda { removeCourse(c.id); }}>Confirm delete</button><button disabled={busy} onClick={lambda { deleting = ""; }}>Cancel</button></div> }
                else { <button disabled={busy} onClick={lambda { deleting = c.id; }}>Delete class</button> }}
            </div> }}
        </section>
        <section><h2 className="text-xl font-bold">Upcoming deadlines</h2>
            {if not openAssignments { <p>No open deadlines.</p> }}
            {for a in openAssignments { <div key={a.id} className="flex justify-between border-b py-3 gap-3">
                <span>{a.course_code + " · " + a.title + " · " + a.due_date + " · " + a.assignment_type}{if a.due_date < data.today { <strong> · Overdue</strong> }}</span>
                <div><button disabled={busy} onClick={lambda { finish(a.id, False); }}>Mark complete</button></div>
            </div> }}
        </section>
        <section><h2 className="text-xl font-bold">Today's study plan</h2>
            {if not daily { <p>No study sessions today.</p> }}
            {for s in daily { <div key={s.id} className="flex justify-between border-b py-3"><span>{s.course_code + " · " + s.description + " · " + str(s.duration_minutes) + " min"}</span><button disabled={busy} onClick={lambda { finish(s.id, True); }}>Complete session</button></div> }}
        </section>
        <section><h2 className="text-xl font-bold">Recommended study sessions</h2><p>Short study blocks are at most 30 minutes. Default totals range from 30 minutes for homework to 2 hours for a final, adjusted by difficulty. Enter hours to set your own total.</p>
            {if not openSessions { <p>Future deadlines generate study sessions automatically.</p> }}
            {for s in openSessions { <div key={s.id} className="flex justify-between border-b py-2"><span>{s.date + " · " + s.course_code + " · " + s.description + " · " + str(s.duration_minutes) + " min"}</span><button disabled={busy} onClick={lambda { finish(s.id, True); }}>Complete</button></div> }}
        </section>
        <section className="border rounded-xl p-4 space-y-3"><h2 className="text-xl font-bold">Add course</h2>
            <form className="flex flex-wrap gap-3" onSubmit={lambda (e: FormEvent) { e.preventDefault(); saveCourse(); }}>
                <input aria-label="Course name" placeholder="Course name" required value={name} onChange={lambda (e: ChangeEvent) { name = e.target.value; }}/>
                <input aria-label="Professor" placeholder="Professor" value={professor} onChange={lambda (e: ChangeEvent) { professor = e.target.value; }}/>
                <input aria-label="Semester" placeholder="Semester" value={semester} onChange={lambda (e: ChangeEvent) { semester = e.target.value; }}/>
                <button disabled={busy}>Save course</button>
            </form>
        </section>
        <section className="border rounded-xl p-4 space-y-3"><h2 className="text-xl font-bold">Add deadline</h2>
            <form className="flex flex-wrap gap-3" onSubmit={lambda (e: FormEvent) { e.preventDefault(); saveAssignment(); }}>
                <select aria-label="Course" required value={courseId} onChange={lambda (e: ChangeEvent) { courseId = e.target.value; }}><option value="">Choose course</option>{for c in data.courses { <option key={c.id} value={c.id}>{c.code}</option> }}</select>
                <input aria-label="Assignment title" required placeholder="Assignment title" value={title} onChange={lambda (e: ChangeEvent) { title = e.target.value; }}/>
                <input aria-label="Due date" required type="date" value={due} onChange={lambda (e: ChangeEvent) { due = e.target.value; }}/>
                <select aria-label="Assignment type" value={kind} onChange={lambda (e: ChangeEvent) { kind = e.target.value; }}>{for k in ["homework", "project", "quiz", "exam", "final", "other"] { <option key={k} value={k}>{k}</option> }}</select>
                <label>Difficulty <input type="number" min="1" max="5" value={difficulty} onChange={lambda (e: ChangeEvent) { difficulty = int(e.target.value); }}/></label>
                <label>Hours (0 = recommended) <input type="number" min="0" max="500" step="0.5" value={hours} onChange={lambda (e: ChangeEvent) { hours = float(e.target.value); }}/></label>
                <button disabled={busy or not data.courses}>Save deadline &amp; plan study</button>
            </form>
        </section>
    </main>;
}
