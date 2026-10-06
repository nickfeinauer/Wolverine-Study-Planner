import from "@jac/mobui" { View, Text, ScrollView, Pressable, TextInput, KeyboardAvoidingView }
import from core.planner.data { PlannerData, planner_data, complete_assignment, complete_session, add_course, add_assignment, delete_course }

def:pub PlannerMobile -> JsxElement {
    has data: PlannerData | None = None, error: str = "", busy: bool = False, notice: str = "", deleting: str = "", courseError: str = "", deadlineError: str = "", saving: str = "",
        name: str = "", professor: str = "", semester: str = "",
        courseId: str = "", title: str = "", due: str = "", kind: str = "homework", difficulty: int = 3, hours: str = "0";
    async def refresh -> None {
        try {
            data = await planner_data(); error = "";
            if not courseId and len(data.courses) == 1 { courseId = data.courses[0].id; }
        }
        except Exception as e { error = str(e); }
    }
    can with entry { refresh(); }
    async def saveCourse -> None {
        if busy { return; }
        courseError = ""; notice = "";
        if not name.strip() { courseError = "Enter a course name before saving."; return; }
        busy = True; saving = "course";
        try {
            course = await add_course(name.strip(), name.strip(), professor.strip(), semester.strip());
            courseId = course.id; name = ""; professor = ""; semester = "";
            await refresh(); notice = "Course saved.";
        } except Exception as e { courseError = str(e); }
        finally { busy = False; saving = ""; }
    }
    async def saveAssignment -> None {
        if busy { return; }
        deadlineError = ""; notice = "";
        if not courseId { deadlineError = "Choose a course before saving this deadline."; return; }
        if not title.strip() { deadlineError = "Enter an assignment title before saving."; return; }
        if not due.strip() { deadlineError = "Enter the due date as YYYY-MM-DD, for example 2026-10-15."; return; }
        busy = True; saving = "deadline";
        try {
            await add_assignment(courseId, title.strip(), due.strip(), kind, difficulty, float(hours.strip() or "0"));
            title = ""; due = "";
            await refresh(); notice = "Deadline saved and study sessions generated.";
        } except Exception as e { deadlineError = str(e); }
        finally { busy = False; saving = ""; }
    }
    async def removeCourse(id: str) -> None {
        busy = True; notice = "";
        try {
            await delete_course(id);
            if courseId == id { courseId = ""; }
            deleting = "";
            await refresh(); notice = "Class and its deadlines and study sessions deleted.";
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
    if data is None {
        return <View style={{"padding": 24}}><Text>Wolverine Study Planner</Text><Text>{error or "Loading planner…"}</Text><Pressable onPress={lambda { refresh(); }}><Text>Retry</Text></Pressable></View>;
    }
    daily = [s for s in data.sessions if s.date == data.today and not s.completed];
    upcoming = [s for s in data.sessions if not s.completed and s.date >= data.today];
    deadlines = [a for a in data.assignments if not a.completed];
    return <KeyboardAvoidingView style={{"flex": 1}} behavior="padding"><ScrollView keyboardShouldPersistTaps="handled" contentContainerStyle={{"padding": 24, "gap": 16, "paddingTop": 60}}>
        <Text style={{"fontSize": 26, "fontWeight": "700", "color": "#00274c"}}>Wolverine Study Planner</Text>
        <Text>{data.today}</Text>
        <Pressable accessibilityRole="button" disabled={busy} onPress={lambda { refresh(); }}><Text>Refresh planner</Text></Pressable>
        {if error { <Text accessibilityRole="alert">{error}</Text> }}
        {if notice { <Text accessibilityLiveRegion="polite">{notice}</Text> }}
        <Text>{str(len(data.courses)) + " classes · " + str(len(deadlines)) + " open deadlines"}</Text>
        <Text style={{"fontSize": 20, "fontWeight": "700"}}>Classes</Text>
        {if not data.courses { <Text>Add your first course below.</Text> }}
        {for c in data.courses { <View key={c.id} style={{"padding": 12, "backgroundColor": "#eef2f6", "gap": 8}}>
            <Text>{c.name + " · " + c.professor + " · " + c.semester}</Text>
            {if deleting == c.id { <View><Text>Delete this class and all its deadlines and study sessions?</Text>
                <Pressable accessibilityRole="button" disabled={busy} onPress={lambda { removeCourse(c.id); }}><Text>Confirm delete</Text></Pressable>
                <Pressable accessibilityRole="button" disabled={busy} onPress={lambda { deleting = ""; }}><Text>Cancel</Text></Pressable>
            </View> } else { <Pressable accessibilityRole="button" disabled={busy} onPress={lambda { deleting = c.id; }}><Text>Delete class</Text></Pressable> }}
        </View> }}
        <Text style={{"fontSize": 20, "fontWeight": "700"}}>Today's study sessions</Text>
        <Text>{str(sum([s.duration_minutes for s in daily])) + " minutes planned"}</Text>
        {if not daily { <Text>No study sessions today.</Text> }}
        {for s in daily { <View key={s.id} style={{"padding": 12, "backgroundColor": "#eef2f6", "gap": 8}}>
            <Text>{s.course_code + " · " + s.description}</Text><Text>{str(s.duration_minutes) + " minutes"}</Text>
            <Pressable accessibilityRole="button" disabled={busy} onPress={lambda { finish(s.id, True); }}><Text>Complete session</Text></Pressable>
        </View> }}
        <Text style={{"fontSize": 20, "fontWeight": "700"}}>Open deadlines</Text>
        {if not deadlines { <Text>No open deadlines.</Text> }}
        {for a in deadlines { <View key={a.id} style={{"padding": 12, "backgroundColor": "#eef2f6", "gap": 8}}>
            <Text>{a.course_code + " · " + a.title}</Text><Text>{a.assignment_type}</Text><Text>{a.due_date + (" · Overdue" if a.due_date < data.today else "")}</Text>
            <Pressable accessibilityRole="button" disabled={busy} onPress={lambda { finish(a.id, False); }}><Text>Complete assignment</Text></Pressable>
        </View> }}
        <Text style={{"fontSize": 20, "fontWeight": "700"}}>Recommended study sessions</Text>
        <Text>New study blocks are at most 30 minutes. Difficulty adjusts the default effort; entered hours set the total directly.</Text>
        {if not upcoming { <Text>Future deadlines generate study sessions automatically.</Text> }}
        {for s in upcoming { <View key={s.id} style={{"padding": 12, "backgroundColor": "#eef2f6", "gap": 8}}>
            <Text>{s.date + " · " + s.course_code + " · " + s.description + " · " + str(s.duration_minutes) + " min"}</Text>
            <Pressable accessibilityRole="button" disabled={busy} onPress={lambda { finish(s.id, True); }}><Text>Complete</Text></Pressable>
        </View> }}
        <View style={{"gap": 12, "padding": 16, "backgroundColor": "#eef2f6", "borderRadius": 12}}>
            <Text style={{"fontSize": 20, "fontWeight": "700"}}>Add course</Text>
            <TextInput style={{"minHeight": 44, "padding": 10, "borderWidth": 1, "borderColor": "#94a3b8", "backgroundColor": "#ffffff", "borderRadius": 6}} accessibilityLabel="Course name" placeholder="Course name" value={name} editable={not busy} onChangeText={lambda (value: str) { name = value; }}/>
            <TextInput style={{"minHeight": 44, "padding": 10, "borderWidth": 1, "borderColor": "#94a3b8", "backgroundColor": "#ffffff", "borderRadius": 6}} accessibilityLabel="Professor" placeholder="Professor" value={professor} editable={not busy} onChangeText={lambda (value: str) { professor = value; }}/>
            <TextInput style={{"minHeight": 44, "padding": 10, "borderWidth": 1, "borderColor": "#94a3b8", "backgroundColor": "#ffffff", "borderRadius": 6}} accessibilityLabel="Semester" placeholder="Semester" value={semester} editable={not busy} onChangeText={lambda (value: str) { semester = value; }}/>
            {if courseError { <Text accessibilityRole="alert" style={{"color": "#b91c1c"}}>{courseError}</Text> }}
            {if notice == "Course saved." { <Text accessibilityLiveRegion="polite">{notice}</Text> }}
            <Pressable accessibilityRole="button" disabled={busy} onPress={lambda { saveCourse(); }} style={{"padding": 14, "backgroundColor": "#ffcb05", "borderRadius": 8, "opacity": 0.5 if busy else 1}}><Text>{"Saving course…" if saving == "course" else "Save course"}</Text></Pressable>
        </View>
        <View style={{"gap": 12, "padding": 16, "backgroundColor": "#eef2f6", "borderRadius": 12}}>
            <Text style={{"fontSize": 20, "fontWeight": "700"}}>Add deadline</Text>
            <Text>Choose course</Text>
            {if not data.courses { <Text>Add a course first.</Text> }}
            {for c in data.courses { <Pressable key={c.id} accessibilityRole="button" accessibilityState={{"selected": courseId == c.id}} disabled={busy} onPress={lambda { courseId = c.id; }} style={{"padding": 12, "backgroundColor": "#ffcb05" if courseId == c.id else "#ffffff"}}><Text>{c.name}</Text></Pressable> }}
            <TextInput style={{"minHeight": 44, "padding": 10, "borderWidth": 1, "borderColor": "#94a3b8", "backgroundColor": "#ffffff", "borderRadius": 6}} accessibilityLabel="Assignment title" placeholder="Assignment title" value={title} editable={not busy} onChangeText={lambda (value: str) { title = value; }}/>
            <Text>Due date (YYYY-MM-DD)</Text>
            <TextInput style={{"minHeight": 44, "padding": 10, "borderWidth": 1, "borderColor": "#94a3b8", "backgroundColor": "#ffffff", "borderRadius": 6}} accessibilityLabel="Due date" placeholder="YYYY-MM-DD" value={due} editable={not busy} autoCapitalize="none" onChangeText={lambda (value: str) { due = value; }}/>
            <Text>Assignment type</Text>
            <View style={{"flexDirection": "row", "flexWrap": "wrap", "gap": 8}}>
                {for k in ["homework", "project", "quiz", "exam", "final", "other"] { <Pressable key={k} accessibilityRole="button" accessibilityState={{"selected": kind == k}} disabled={busy} onPress={lambda { kind = k; }} style={{"padding": 12, "backgroundColor": "#ffcb05" if kind == k else "#ffffff"}}><Text>{k}</Text></Pressable> }}
            </View>
            <Text>Difficulty (1–5)</Text>
            <View style={{"flexDirection": "row", "gap": 8}}>
                {for d in [1, 2, 3, 4, 5] { <Pressable key={str(d)} accessibilityRole="button" accessibilityLabel={"Difficulty " + str(d)} accessibilityState={{"selected": difficulty == d}} disabled={busy} onPress={lambda { difficulty = d; }} style={{"padding": 12, "backgroundColor": "#ffcb05" if difficulty == d else "#ffffff"}}><Text>{str(d)}</Text></Pressable> }}
            </View>
            <Text>Hours (0 = recommended)</Text>
            <TextInput style={{"minHeight": 44, "padding": 10, "borderWidth": 1, "borderColor": "#94a3b8", "backgroundColor": "#ffffff", "borderRadius": 6}} accessibilityLabel="Hours" value={hours} keyboardType="decimal-pad" editable={not busy} onChangeText={lambda (value: str) { hours = value; }}/>
            {if deadlineError { <Text accessibilityRole="alert" style={{"color": "#b91c1c"}}>{deadlineError}</Text> }}
            {if notice == "Deadline saved and study sessions generated." { <Text accessibilityLiveRegion="polite">{notice}</Text> }}
            <Pressable accessibilityRole="button" disabled={busy} onPress={lambda { saveAssignment(); }} style={{"padding": 14, "backgroundColor": "#ffcb05", "borderRadius": 8, "opacity": 0.5 if busy else 1}}><Text>{"Saving deadline…" if saving == "deadline" else "Save deadline & plan study"}</Text></Pressable>
        </View>
    </ScrollView></KeyboardAvoidingView>;
}
