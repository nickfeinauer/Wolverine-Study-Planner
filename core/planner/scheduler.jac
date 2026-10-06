import datetime;
import math;
import from zoneinfo { ZoneInfo }

obj SessionPlan {
    has date: str, duration_minutes: int;
}

def today -> str {
    return datetime.datetime.now(ZoneInfo("America/Detroit")).date().isoformat();
}

def recommended_minutes(assignment_type: str, difficulty: int, estimated_hours: float = 0.0) -> int {
    baselines = {"homework": 0.5, "quiz": 0.5, "project": 1.5, "exam": 1.0, "final": 2.0, "other": 0.5};
    hours = estimated_hours if estimated_hours > 0 else baselines[assignment_type] * [0.70, 0.85, 1.0, 1.25, 1.50][difficulty - 1];
    return max(1, int(round(hours * 60)));
}

def schedule(due_date: str, assignment_type: str, difficulty: int, estimated_hours: float = 0.0, start: str = "") -> list[SessionPlan] {
    due = datetime.date.fromisoformat(due_date);
    first = datetime.date.fromisoformat(start or today());
    available = (due - first).days;
    if available <= 0 { return []; }
    total = recommended_minutes(assignment_type, difficulty, estimated_hours);
    days = min(available, 28, max(1, int(math.ceil(total / 30.0))));
    weights = [1.0 + 0.5 * i / max(1, days - 1) for i in range(days)];
    weight = sum(weights);
    remaining = total;
    result: list[SessionPlan] = [];
    for i in range(days) {
        minutes = int(total * weights[i] / weight) if i < days - 1 else remaining;
        remaining -= minutes;
        blocks = max(1, int(math.ceil(minutes / 30.0)));
        base = minutes // blocks;
        extra = minutes % blocks;
        for block in range(blocks) {
            result.append(SessionPlan(date=(first + datetime.timedelta(days=i)).isoformat(), duration_minutes=base + (1 if block < extra else 0)));
        }
    }
    return result;
}
