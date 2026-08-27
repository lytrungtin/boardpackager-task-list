module Tasks
  class CompletionsController < ApplicationController
    def create
      task = Task.find(params[:task_id])
      task.complete!

      redirect_to task, notice: "Task marked as completed."
    end

    def destroy
      task = Task.find(params[:task_id])
      task.uncomplete!

      redirect_to task, notice: "Task marked as not completed."
    end
  end
end
