class TasksController < ApplicationController
  before_action :set_task, only: %i[show edit update]

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
