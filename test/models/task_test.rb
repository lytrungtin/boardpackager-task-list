require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "valid with title and due_at" do
    task = Task.new(title: "Write report", due_at: 1.day.from_now)

    assert task.valid?
  end

  test "invalid without title" do
    task = Task.new(due_at: 1.day.from_now)

    assert_not task.valid?
    assert_includes task.errors[:title], "can't be blank"
  end

  test "invalid without due_at" do
    task = Task.new(title: "Write report")

    assert_not task.valid?
    assert_includes task.errors[:due_at], "can't be blank"
  end

  test "valid without description" do
    task = Task.new(title: "Write report", due_at: 1.day.from_now)

    assert task.valid?
  end

  test "persists created_at automatically" do
    task = Task.create!(title: "Write report", due_at: 1.day.from_now)

    assert_not_nil task.reload.created_at
  end

  test "complete! stamps completed_at" do
    task = tasks(:due_tomorrow)

    travel_to Time.zone.local(2026, 8, 27, 12, 0, 0) do
      task.complete!

      assert_equal Time.zone.local(2026, 8, 27, 12, 0, 0), task.reload.completed_at
    end
  end

  test "uncomplete! clears completed_at" do
    task = tasks(:done)

    task.uncomplete!

    assert_nil task.reload.completed_at
  end

  test "completed? reflects completed_at presence" do
    assert tasks(:done).completed?
    assert_not tasks(:due_tomorrow).completed?
  end

  test "ordered sorts by due_at ascending" do
    Task.delete_all
    later = Task.create!(title: "Later", due_at: 3.days.from_now)
    sooner = Task.create!(title: "Sooner", due_at: 1.day.from_now)

    assert_equal [ sooner, later ], Task.ordered.to_a
  end

  test "overdue scope returns only past-due incomplete tasks" do
    Task.delete_all
    overdue = Task.create!(title: "Late", due_at: 1.hour.ago)
    Task.create!(title: "Late but done", due_at: 1.hour.ago, completed_at: 30.minutes.ago)
    Task.create!(title: "Future", due_at: 1.day.from_now)

    assert_equal [ overdue ], Task.overdue.to_a
  end

  test "overdue? matches the scope logic" do
    task = tasks(:due_tomorrow)

    assert_not task.overdue?

    travel_to 2.days.from_now do
      assert task.overdue?
    end

    assert_not tasks(:done).overdue?
  end

  test "due_today includes everything due before end of today, even overdue" do
    Task.delete_all
    just_in_time = Task.create!(title: "Just in time", due_at: Time.zone.now.end_of_day - 1.minute)
    late = Task.create!(title: "Late", due_at: 1.day.ago)
    Task.create!(title: "Tomorrow", due_at: Time.zone.now.end_of_day + 1.hour)

    results = Task.due_today.to_a

    assert_includes results, just_in_time
    assert_includes results, late
    assert_equal 2, results.size
  end
end
