class TasksController < ApplicationController
  def show
    @task = Task.find(params[:id])
  end

  def new
    @task = Task.new
  end

  def create
    @task = Task.new(task_params)

    if @task.save
      redirect_to @task, notice: "Task was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

    # Only these three attributes are user-editable (brief item 4);
    # created_at/completed_at can never be mass-assigned.
    def task_params
      params.expect(task: [ :title, :description, :due_at ])
    end
end
