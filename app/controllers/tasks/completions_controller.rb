module Tasks
  class CompletionsController < ApplicationController
    def create
      task = Current.user.tasks.find(params[:task_id])
      task.complete!

      redirect_to task, notice: "Task marked as completed."
    rescue ActiveRecord::StaleObjectError
      redirect_to task, alert: "Task was updated by someone else. Please reload and try again."
    end

    def destroy
      task = Current.user.tasks.find(params[:task_id])
      task.uncomplete!

      redirect_to task, notice: "Task marked as not completed."
    rescue ActiveRecord::StaleObjectError
      redirect_to task, alert: "Task was updated by someone else. Please reload and try again."
    end
  end
end
