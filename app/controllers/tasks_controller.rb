class TasksController < ApplicationController
  before_action :set_task, only: %i[show edit update destroy]

  def show
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

  def edit
  end

  def update
    if @task.update(task_params)
      redirect_to @task, notice: "Task was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy!

    # The task list page lands with item 6; until then the natural place
    # to land after deleting is the new-task form.
    redirect_to new_task_url, status: :see_other, notice: "Task was successfully deleted."
  end

  private

    def set_task
      @task = Task.find(params[:id])
    end

    # Only these three attributes are user-editable (brief item 4);
    # created_at/completed_at can never be mass-assigned.
    def task_params
      params.expect(task: [ :title, :description, :due_at ])
    end
end
