require "test_helper"

module Tasks
  class CompletionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in_as users(:alice)
    end

    test "POST /tasks/:id/completion marks the task as completed" do
      task = tasks(:due_tomorrow)

      post task_completion_url(task)

      assert task.reload.completed?
      assert_redirected_to task_url(task)
    end

    test "DELETE /tasks/:id/completion marks the task as not completed" do
      task = tasks(:done)

      delete task_completion_url(task)

      assert_not task.reload.completed?
      assert_redirected_to task_url(task)
    end
  end
end
