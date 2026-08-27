require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  test "GET /tasks/new renders form" do
    get new_task_url

    assert_response :success
    assert_select "form"
  end

  test "POST /tasks creates task and redirects to show" do
    assert_difference("Task.count", 1) do
      post tasks_url, params: { task: { title: "Write report", description: "Q3 numbers", due_at: 1.day.from_now } }
    end

    assert_redirected_to task_url(Task.last)
  end
end
