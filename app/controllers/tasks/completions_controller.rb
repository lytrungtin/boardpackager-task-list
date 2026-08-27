module Tasks
  class CompletionsController < ApplicationController
    def create
      task = Current.user.tasks.find(params[:task_id])
      task.complete!

      redirect_to task, notice: "Task marked as completed."
    end

    def destroy
      task = Current.user.tasks.find(params[:task_id])
      task.uncomplete!

      redirect_to task, notice: "Task marked as not completed."
    end
  end
end
