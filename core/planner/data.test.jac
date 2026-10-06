import tempfile;
import from jaclang.testing.testing { JacTestClient }

test "planner API persists graph and completion across clients" {
    client = JacTestClient.from_file("core/planner/data.jac", base_path=tempfile.mkdtemp());
    try {
        made = client.post("/function/add_course", json={"code": "TEST", "name": "Isolated planner test"});
        assert made.ok;
        course = made.data["result"];
        deadline = client.post("/function/add_assignment", json={"course_id": course["id"], "title": "Exam", "due_date": "2099-10-15", "assignment_type": "exam", "difficulty": 3, "estimated_hours": 7.0});
        assert deadline.ok, str(deadline.data);
        defaults = client.post("/function/add_assignment", json={"course_id": course["id"], "title": "Default values", "due_date": "2000-01-01"});
        assert defaults.ok, str(defaults.data);
        assert defaults.data["result"]["difficulty"] == 3;
        assignment = deadline.data["result"];
        loaded = client.post("/function/planner_data").data["result"];
        assert len(loaded["courses"]) == 1;
        assert len(loaded["assignments"]) == 2;
        assert len(loaded["sessions"]) > 7;
        assert sum([s["duration_minutes"] for s in loaded["sessions"]]) == 420;
        again = client.post("/function/generate_study", json={"id": assignment["id"]});
        assert again.ok;
        assert len(client.post("/function/planner_data").data["result"]["sessions"]) == len(loaded["sessions"]);
        original = client.post("/function/planner_data").data["result"]["sessions"][0];
        assert client.post("/function/complete_session", json={"id": original["id"]}).ok;
        assert client.post("/function/generate_study", json={"id": assignment["id"]}).ok;
        replanned = client.post("/function/planner_data").data["result"]["sessions"];
        assert sum([s["duration_minutes"] for s in replanned]) == 420;
        assert any([s["id"] == original["id"] and s["completed"] for s in replanned]);
        assert sum([s["duration_minutes"] for s in replanned if not s["completed"]]) == 420 - original["duration_minutes"];
        finished = client.post("/function/complete_assignment", json={"id": assignment["id"]});
        assert finished.ok;
        loaded = client.post("/function/planner_data").data["result"];
        assert any([a["completed"] and a["id"] == assignment["id"] for a in loaded["assignments"]]);
        assert all([s["completed"] for s in loaded["sessions"]]);
    } finally { client.close(); }
}

test "delete class cascades and leaves other classes intact" {
    client = JacTestClient.from_file("core/planner/data.jac", base_path=tempfile.mkdtemp());
    try {
        course = client.post("/function/add_course", json={"code": "DELETE", "name": "Delete me"}).data["result"];
        keep = client.post("/function/add_course", json={"code": "KEEP", "name": "Keep me"}).data["result"];
        assignment = client.post("/function/add_assignment", json={"course_id": course["id"], "title": "Exam", "due_date": "2099-10-15"}).data["result"];
        assert client.post("/function/delete_course", json={"id": course["id"]}).ok;
        loaded = client.post("/function/planner_data").data["result"];
        assert len(loaded["courses"]) == 1 and loaded["courses"][0]["id"] == keep["id"];
        assert not loaded["assignments"] and not loaded["sessions"];
        assert not client.post("/function/complete_assignment", json={"id": assignment["id"]}).ok;
        assert not client.post("/function/delete_course", json={"id": course["id"]}).ok;
    } finally { client.close(); }
}

test "overdue replan reports failure without deleting the existing plan" {
    client = JacTestClient.from_file("core/planner/data.jac", base_path=tempfile.mkdtemp());
    try {
        course = client.post("/function/add_course", json={"code": "PAST", "name": "Past deadline"}).data["result"];
        assignment = client.post("/function/add_assignment", json={"course_id": course["id"], "title": "Overdue", "due_date": "2000-01-01"}).data["result"];
        before = client.post("/function/planner_data").data["result"];
        assert not client.post("/function/generate_study", json={"id": assignment["id"]}).ok;
        after = client.post("/function/planner_data").data["result"];
        assert len(after["assignments"]) == len(before["assignments"]);
        assert after["assignments"][0]["id"] == before["assignments"][0]["id"];
        assert after["assignments"][0]["due_date"] == "2000-01-01";
        assert not after["sessions"] and not before["sessions"];
    } finally { client.close(); }
}
