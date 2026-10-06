import from core.planner.scheduler { schedule }

test "study time is conserved and dates precede deadline" {
    plans = schedule("2026-10-15", "exam", 3, 7.0, "2026-10-10");
    assert len(set([p.date for p in plans])) == 5;
    assert sum([p.duration_minutes for p in plans]) == 420;
    assert all([p.date < "2026-10-15" and p.date >= "2026-10-10" for p in plans]);
    assert sum([p.duration_minutes for p in plans if p.date == "2026-10-14"]) >= sum([p.duration_minutes for p in plans if p.date == "2026-10-10"]);
}
test "past and same day deadlines have no future study sessions" {
    assert schedule("2026-10-05", "homework", 3, start="2026-10-05") == [];
    assert schedule("2026-10-04", "exam", 3, start="2026-10-05") == [];
}

test "short effort does not become tiny daily sessions" {
    plans = schedule("2026-11-01", "homework", 5, 0.5, "2026-10-05");
    assert len(plans) == 1;
    assert plans[0].date == "2026-10-05";
    assert plans[0].duration_minutes == 30;
}

test "large effort starts earlier and uses manageable blocks" {
    plans = schedule("2026-11-01", "final", 3, 15.0, "2026-10-05");
    assert len(set([p.date for p in plans])) == 27;
    assert plans[0].date == "2026-10-05";
    assert sum([p.duration_minutes for p in plans]) == 900;
    assert all([0 < p.duration_minutes <= 30 for p in plans]);
    rushed = schedule("2026-10-06", "project", 3, 10.0, "2026-10-05");
    assert sum([p.duration_minutes for p in rushed]) == 600;
    assert all([p.date == "2026-10-05" and p.duration_minutes <= 30 for p in rushed]);
}

test "difficulty scales defaults but explicit effort overrides it" {
    easy = schedule("2026-11-01", "exam", 1, start="2026-10-05");
    hard = schedule("2026-11-01", "exam", 5, start="2026-10-05");
    explicit = schedule("2026-11-01", "exam", 5, 2.0, "2026-10-05");
    assert sum([p.duration_minutes for p in easy]) == 42;
    assert sum([p.duration_minutes for p in hard]) == 90;
    assert sum([p.duration_minutes for p in explicit]) == 120;
}
