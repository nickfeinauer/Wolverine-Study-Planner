import argparse;
import asyncio;
import sys;
import os;
import from jaclang.server { sv_client }
import from core.planner.data { planner_data, add_course, add_assignment, complete_assignment, complete_session, generate_study }

async def main(argv: list[str]) -> int {
    sv_client.register("planner", os.environ.get("JAC_APP_PLANNER_URL", "http://127.0.0.1:8001"), route=os.environ.get("JAC_APP_PLANNER_ROUTE", "/api/planner"));
    parser = argparse.ArgumentParser(description="Shared academic planner (start jac run first)");
    commands = parser.add_subparsers(dest="command", required=True);
    for command in ["today", "courses", "assignments"] { commands.add_parser(command); }
    add = commands.add_parser("add");
    add.add_argument("kind", choices=["course", "assignment"]);
    add.add_argument("--code", `default=""); add.add_argument("--name", `default="");
    add.add_argument("--professor", `default=""); add.add_argument("--semester", `default="");
    add.add_argument("--course", `default=""); add.add_argument("--title", `default=""); add.add_argument("--due", `default="");
    add.add_argument("--type", dest="assignment_type", `default="homework");
    add.add_argument("--difficulty", `type=int, `default=3); add.add_argument("--hours", `type=float, `default=0.0);
    complete = commands.add_parser("complete"); complete.add_argument("id"); complete.add_argument("--session", action="store_true");
    study = commands.add_parser("study"); study.add_argument("id", nargs="?", `default="");
    args = parser.parse_args(argv);
    try {
        if args.command == "add" {
            if args.kind == "course" {
                course = await add_course(args.code, args.name, args.professor, args.semester);
                print("Course saved: " + course.id);
            } else {
                assignment = await add_assignment(args.course, args.title, args.due, args.assignment_type, args.difficulty, args.hours);
                print("Deadline saved: " + assignment.id);
            }
            return 0;
        }
        if args.command == "complete" {
            if args.session { await complete_session(args.id); } else { await complete_assignment(args.id); }
            print("Completed"); return 0;
        }
        if args.command == "study" and args.id {
            count = await generate_study(args.id); print(str(count) + " study sessions"); return 0;
        }
        data = await planner_data();
        if args.command == "courses" {
            for c in data.courses { print(c.id + "  " + c.code + "  " + c.name); }
        } elif args.command == "assignments" {
            for a in data.assignments { print(a.id + "  " + a.course_code + "  " + a.title + "  " + a.due_date + ("  completed" if a.completed else "  open")); }
        } else {
            print("Study plan " + data.today);
            for s in data.sessions {
                if not s.completed and (args.command == "study" or s.date == data.today) { print(s.id + "  " + s.date + "  " + s.course_code + "  " + s.description + "  " + str(s.duration_minutes) + " min"); }
            }
            if args.command == "today" {
                print("Open deadlines");
                for a in data.assignments {
                    if not a.completed { print(a.id + "  " + a.course_code + "  " + a.title + "  " + a.due_date); }
                }
            }
        }
        return 0;
    } except Exception as e {
        print("Planner error: " + str(e), file=sys.stderr); return 1;
    }
}
with entry:__main__ { sys.`exit(asyncio.run(main(sys.argv[1:]))); }
