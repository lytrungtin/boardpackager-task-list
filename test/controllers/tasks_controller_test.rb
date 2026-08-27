require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:alice)
  end

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
    assert_select "h1", text: /#{Regexp.escape(task.title)}/
    assert_match task.description, response.body
    assert_match task.created_at.strftime("%b %-d, %Y at %H:%M"), response.body
    assert_match task.due_at.strftime("%b %-d, %Y at %H:%M"), response.body
  end

  test "GET /tasks/:id for a missing task returns 404" do
    get task_url(id: 999_999)

    assert_response :not_found
  end

  test "GET /tasks/:id/edit renders form with current values" do
    task = tasks(:due_tomorrow)

    get edit_task_url(task)

    assert_response :success
    assert_select "input[name='task[title]'][value=?]", task.title
  end

  test "PATCH /tasks/:id updates editable fields and redirects" do
    task = tasks(:due_tomorrow)

    patch task_url(task), params: { task: { title: "Updated title", description: "Updated body", due_at: 3.days.from_now } }

    assert_redirected_to task_url(task)
    assert_equal "Updated title", task.reload.title
  end

  test "PATCH /tasks/:id with blank title returns 422 and keeps old value" do
    task = tasks(:due_tomorrow)

    patch task_url(task), params: { task: { title: "" } }

    assert_response :unprocessable_entity
    assert_equal "Prepare board meeting agenda", task.reload.title
  end

  test "PATCH /tasks/:id ignores created_at and completed_at params" do
    task = tasks(:due_tomorrow)
    original_created_at = task.created_at

    patch task_url(task), params: { task: { title: "Still editable", created_at: 10.years.ago, completed_at: Time.current } }

    assert_equal original_created_at, task.reload.created_at
    assert_nil task.completed_at
    assert_equal "Still editable", task.title
  end

  test "DELETE /tasks/:id removes the task and redirects to the list" do
    task = tasks(:due_tomorrow)

    assert_difference("Task.count", -1) do
      delete task_url(task)
    end

    assert_response :see_other
    assert_redirected_to tasks_url
  end

  test "deleted task is gone afterwards" do
    task = tasks(:due_tomorrow)

    delete task_url(task)
    get task_url(task)

    assert_response :not_found
  end

  test "GET / lists tasks sorted by due date ascending" do
    Task.delete_all
    later = users(:alice).tasks.create!(title: "Zebra due later", due_at: 5.days.from_now)
    sooner = users(:alice).tasks.create!(title: "Alpha due sooner", due_at: 1.day.from_now)

    get root_url

    assert_response :success
    assert_operator response.body.index(sooner.title), :<, response.body.index(later.title)
  end

  test "GET / marks overdue tasks with a badge" do
    Task.delete_all
    users(:alice).tasks.create!(title: "Very late task", due_at: 2.days.ago)
    users(:alice).tasks.create!(title: "Future task", due_at: 2.days.from_now)

    get root_url

    assert_select ".badge-overdue", count: 1
  end

  test "GET /?filter=due_today hides tasks due after today" do
    Task.delete_all
    today = users(:alice).tasks.create!(title: "Finish today task", due_at: Time.zone.now.end_of_day - 1.minute)
    users(:alice).tasks.create!(title: "Next week task", due_at: 7.days.from_now)

    get root_url(filter: "due_today")

    assert_response :success
    assert_match today.title, response.body
    assert_no_match(/Next week task/, response.body)
  end

  test "GET / lists only the signed-in user's tasks" do
    get root_url

    assert_match tasks(:due_tomorrow).title, response.body
    assert_no_match(/#{Regexp.escape(tasks(:bob_task).title)}/, response.body)
  end

  test "opening another user's task returns 404" do
    get task_url(tasks(:bob_task))

    assert_response :not_found
  end

  test "created tasks belong to the signed-in user" do
    post tasks_url, params: { task: { title: "Mine", due_at: 1.day.from_now } }

    assert_equal users(:alice), Task.last.user
  end

  test "GET /?filter=completed lists only completed tasks" do
    get root_url(filter: "completed")

    assert_match tasks(:done).title, response.body
    assert_no_match(/#{Regexp.escape(tasks(:due_tomorrow).title)}/, response.body)
  end

  test "GET /?filter=overdue lists only overdue tasks" do
    overdue = users(:alice).tasks.create!(title: "Missed deadline item", due_at: 2.days.ago)

    get root_url(filter: "overdue")

    assert_match overdue.title, response.body
    assert_no_match(/#{Regexp.escape(tasks(:due_tomorrow).title)}/, response.body)
  end

  test "GET / with an unknown filter safely falls back to all tasks" do
    get root_url(filter: "destroy_all")

    assert_response :success
    assert_match tasks(:due_tomorrow).title, response.body
    assert_match tasks(:done).title, response.body
  end
end
