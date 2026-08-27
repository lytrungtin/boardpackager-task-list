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

  test "POST /tasks without title returns 422 and creates nothing" do
    assert_no_difference("Task.count") do
      post tasks_url, params: { task: { title: "", description: "No title given", due_at: 1.day.from_now } }
    end

    assert_response :unprocessable_entity
    assert_select ".error-box li", text: "Title can't be blank"
  end

  test "invalid submit re-renders the form with entered values preserved" do
    post tasks_url, params: { task: { title: "", description: "Keep this text", due_at: "" } }

    assert_response :unprocessable_entity
    assert_select "textarea", text: /Keep this text/
    assert_select ".field-error", text: "Due at can't be blank"
  end
end
