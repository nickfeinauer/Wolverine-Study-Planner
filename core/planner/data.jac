import uuid;
import datetime;
import math;
import from core.planner.scheduler { schedule, today, recommended_minutes }

node Course {
    has id: str = "", code: str = "", name: str = "", professor: str = "", semester: str = "";
}
node Assignment {
    has id: str = "", course_id: str = "", course_code: str = "", title: str = "", due_date: str = "", assignment_type: str = "homework", difficulty: int = 3, estimated_hours: float = 0.0, completed: bool = False;
}
node StudySession {
    has id: str = "", assignment_id: str = "", course_code: str = "", date: str = "", duration_minutes: int = 0, description: str = "", completed: bool = False;
}
obj PlannerData {
    has courses: list[Course] = [], assignments: list[Assignment] = [], sessions: list[StudySession] = [], today: str = "";
}

def:pub planner_data -> PlannerData {
    courses = [root.shared-->[?:Course]];
    assignments: list[Assignment] = [];
    sessions: list[StudySession] = [];
    for course in courses {
        for assignment in [course-->[?:Assignment]] {
            assignments.append(assignment);
            sessions.extend([assignment-->[?:StudySession]]);
        }
    }
    assignments.sort(key=lambda (a: Assignment) { a.due_date; });
    sessions.sort(key=lambda (s: StudySession) { s.date; });
    return PlannerData(courses=courses, assignments=assignments, sessions=sessions, today=today());
}

def:pub add_course(code: str, name: str, professor: str = "", semester: str = "") -> Course {
    if not code.strip() or not name.strip() { raise ValueError("Course code and name are required"); }
    for course in [root.shared-->[?:Course]] {
        if course.code.lower() == code.strip().lower() and course.semester == semester.strip() {
            raise ValueError("That course already exists for this semester");
        }
    }
    return root.shared ++> Course(id=str(uuid.uuid4()), code=code.strip(), name=name.strip(), professor=professor.strip(), semester=semester.strip());
}

def:pub delete_course(id: str) -> bool {
    for course in [root.shared-->[?:Course]] {
        if course.id == id {
            for assignment in [course-->[?:Assignment]] {
                for session in [assignment-->[?:StudySession]] { del session; }
                del assignment;
            }
            del course;
            return True;
        }
    }
    raise ValueError("Course not found");
}

def find_assignment(id: str) -> Assignment {
    for assignment in planner_data().assignments {
        if assignment.id == id { return assignment; }
    }
    raise ValueError("Assignment not found");
}

def generate(assignment: Assignment) -> int {
    existing = [assignment-->[?:StudySession]];
    if existing or assignment.completed { return len(existing); }
    plans = schedule(assignment.due_date, assignment.assignment_type, assignment.difficulty, assignment.estimated_hours);
    for plan in plans {
        assignment ++> StudySession(id=str(uuid.uuid4()), assignment_id=assignment.id, course_code=assignment.course_code, date=plan.date, duration_minutes=plan.duration_minutes, description="Study for " + assignment.title);
    }
    return len(plans);
}

def validate_assignment(title: str, due_date: str, assignment_type: str, difficulty: int, estimated_hours: float) {
    if not title.strip() { raise ValueError("Title is required"); }
    try { valid_date = datetime.date.fromisoformat(due_date).isoformat() == due_date; }
    except ValueError { valid_date = False; }
    if not valid_date { raise ValueError("Enter a due date in YYYY-MM-DD format"); }
    if assignment_type not in ["homework", "project", "quiz", "exam", "final", "other"] { raise ValueError("Invalid assignment type"); }
    if difficulty < 1 or difficulty > 5 { raise ValueError("Difficulty must be 1 through 5"); }
    if not math.isfinite(estimated_hours) or estimated_hours < 0 or estimated_hours > 500 { raise ValueError("Estimated hours must be between 0 and 500"); }
}

def:pub add_assignment(course_id: str, title: str, due_date: str, assignment_type: str = "homework", difficulty: int = 3, estimated_hours: float = 0.0) -> Assignment {
    difficulty = int(difficulty);
    estimated_hours = float(estimated_hours);
    validate_assignment(title, due_date, assignment_type, difficulty, estimated_hours);
    for course in [root.shared-->[?:Course]] {
        if course.id == course_id {
            assignment = course ++> Assignment(id=str(uuid.uuid4()), course_id=course.id, course_code=course.code, title=title.strip(), due_date=due_date, assignment_type=assignment_type, difficulty=difficulty, estimated_hours=estimated_hours);
            generate(assignment);
            return assignment;
        }
    }
    raise ValueError("Choose an existing course");
}

def:pub generate_study(id: str) -> int {
    assignment = find_assignment(id);
    if assignment.completed { return 0; }
    sessions = [assignment-->[?:StudySession]];
    credited = sum([s.duration_minutes for s in sessions if s.completed]);
    remaining = max(0, recommended_minutes(assignment.assignment_type, assignment.difficulty, assignment.estimated_hours) - credited);
    plans = schedule(assignment.due_date, assignment.assignment_type, assignment.difficulty, remaining / 60.0) if remaining > 0 else [];
    if remaining > 0 and not plans {
        raise ValueError("This deadline is today or overdue. There are no days before the deadline to replan; the existing study plan has been kept.");
    }
    for session in sessions { if not session.completed { del session; } }
    for plan in plans {
        assignment ++> StudySession(id=str(uuid.uuid4()), assignment_id=assignment.id, course_code=assignment.course_code, date=plan.date, duration_minutes=plan.duration_minutes, description="Study for " + assignment.title);
    }
    return len(plans);
}

def:pub complete_assignment(id: str) -> bool {
    assignment = find_assignment(id);
    assignment.completed = True;
    for session in [assignment-->[?:StudySession]] { session.completed = True; }
    return True;
}

def:pub complete_session(id: str) -> bool {
    for session in planner_data().sessions {
        if session.id == id { session.completed = True; return True; }
    }
    raise ValueError("Study session not found");
}


def:pub update_course(id: str, code: str, name: str, professor: str = "", semester: str = "") -> Course {
    if not code.strip() or not name.strip() { raise ValueError("Course code and name are required"); }
    courses = [root.shared-->[?:Course]];
    for c in courses {
        if c.id != id and c.code.lower() == code.strip().lower() and c.semester == semester.strip() { raise ValueError("That course already exists"); }
    }
    for c in courses {
        if c.id == id {
            c.code = code.strip(); c.name = name.strip(); c.professor = professor.strip(); c.semester = semester.strip();
            for a in [c-->[?:Assignment]] {
                a.course_code = c.code;
                for s in [a-->[?:StudySession]] { s.course_code = c.code; }
            }
            return c;
        }
    }
    raise ValueError("Course not found");
}

def:pub update_assignment(id: str, title: str, due_date: str, assignment_type: str = "homework", difficulty: int = 3, estimated_hours: float = 0.0) -> Assignment {
    difficulty = int(difficulty);
    estimated_hours = float(estimated_hours);
    validate_assignment(title, due_date, assignment_type, difficulty, estimated_hours);
    a = find_assignment(id);
    if a.completed { raise ValueError("Completed assignments cannot be rescheduled"); }
    if any([s.completed for s in [a-->[?:StudySession]]]) { raise ValueError("Assignments with completed study sessions cannot be rescheduled"); }
    for s in [a-->[?:StudySession]] { del s; }
    a.title = title.strip(); a.due_date = due_date; a.assignment_type = assignment_type; a.difficulty = difficulty; a.estimated_hours = estimated_hours;
    generate(a);
    return a;
}
