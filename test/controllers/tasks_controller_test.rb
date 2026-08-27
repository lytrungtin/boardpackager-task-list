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

  test "GET /tasks/:id shows all task fields" do
    task = tasks(:due_tomorrow)

    get task_url(task)

    assert_response :success
    assert_select "h1", text: task.title
    assert_match task.description, response.body
    assert_match task.created_at.strftime("%b %-d, %Y at %H:%M"), response.body
    assert_match task.due_at.strftime("%b %-d, %Y at %H:%M"), response.body
  end

  test "GET /tasks/:id for a missing task returns 404" do
    get task_url(id: 999_999)

    assert_response :not_found
  end
end
