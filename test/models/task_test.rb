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
end
