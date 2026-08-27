class TasksController < ApplicationController
  before_action :set_task, only: %i[show edit update destroy]

  def index
    @tasks = Current.user.tasks.ordered
    # A proper whitelist arrives with the filters story; keep it simple now.
    @tasks = @tasks.due_today if params[:filter] == "due_today"
  end

  def show
  end

  def new
    @task = Task.new
  end

  def create
    @task = Current.user.tasks.new(task_params)

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

    redirect_to tasks_url, status: :see_other, notice: "Task was successfully deleted."
  end

  private

    # Scope the query instead of loading-then-authorizing: other users' tasks
    # are indistinguishable from missing ones (404), which leaks nothing.
    def set_task
      @task = Current.user.tasks.find(params[:id])
    end

    # Only these three attributes are user-editable (brief item 4);
    # created_at/completed_at can never be mass-assigned.
    def task_params
      params.expect(task: [ :title, :description, :due_at ])
    end
end
