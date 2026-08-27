class TasksController < ApplicationController
  before_action :set_task, only: %i[show edit update destroy]

  # Filters are looked up in a whitelist; anything else falls back to "all".
  # Params can therefore never call arbitrary model methods.
  FILTERS = {
    "active" => :active,
    "completed" => :completed,
    "overdue" => :overdue,
    "due_today" => :due_today
  }.freeze

  def index
    @tasks = Current.user.tasks.ordered
    @tasks = @tasks.public_send(FILTERS[params[:filter]]) if FILTERS.key?(params[:filter])
    # Search composes with whichever filter is active.
    @tasks = @tasks.search(params[:q])
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
