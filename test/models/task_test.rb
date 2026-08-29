require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "valid with title and due_at" do
    task = Task.new(user: users(:alice), title: "Write report", due_at: 1.day.from_now)

    assert task.valid?
  end

  test "invalid without title" do
    task = Task.new(user: users(:alice), due_at: 1.day.from_now)

    assert_not task.valid?
    assert_includes task.errors[:title], "can't be blank"
  end

  test "invalid without due_at" do
    task = Task.new(user: users(:alice), title: "Write report")

    assert_not task.valid?
    assert_includes task.errors[:due_at], "can't be blank"
  end

  test "valid without description" do
    task = Task.new(user: users(:alice), title: "Write report", due_at: 1.day.from_now)

    assert task.valid?
  end

  test "persists created_at automatically" do
    task = Task.create!(user: users(:alice), title: "Write report", due_at: 1.day.from_now)

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
    later = Task.create!(user: users(:alice), title: "Later", due_at: 3.days.from_now)
    sooner = Task.create!(user: users(:alice), title: "Sooner", due_at: 1.day.from_now)

    assert_equal [ sooner, later ], Task.ordered.to_a
  end

  test "overdue scope returns only past-due incomplete tasks" do
    Task.delete_all
    overdue = Task.create!(user: users(:alice), title: "Late", due_at: 1.hour.ago)
    Task.create!(user: users(:alice), title: "Late but done", due_at: 1.hour.ago, completed_at: 30.minutes.ago)
    Task.create!(user: users(:alice), title: "Future", due_at: 1.day.from_now)

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
    just_in_time = Task.create!(user: users(:alice), title: "Just in time", due_at: Time.zone.now.end_of_day - 1.minute)
    late = Task.create!(user: users(:alice), title: "Late", due_at: 1.day.ago)
    Task.create!(user: users(:alice), title: "Tomorrow", due_at: Time.zone.now.end_of_day + 1.hour)

    results = Task.due_today.to_a

    assert_includes results, just_in_time
    assert_includes results, late
    assert_equal 2, results.size
  end

  test "completed scope returns only completed tasks" do
    assert_includes Task.completed.to_a, tasks(:done)
    assert_not_includes Task.completed.to_a, tasks(:due_tomorrow)
  end

  test "active scope returns only open tasks" do
    assert_includes Task.active.to_a, tasks(:due_tomorrow)
    assert_not_includes Task.active.to_a, tasks(:done)
  end

  test "search matches title and description case-insensitively" do
    Task.delete_all
    by_title = Task.create!(user: users(:alice), title: "Fix ELEVATOR button", due_at: 1.day.from_now)
    by_description = Task.create!(user: users(:alice), title: "Lobby work", description: "elevator inspection paperwork", due_at: 2.days.from_now)
    Task.create!(user: users(:alice), title: "Unrelated", due_at: 3.days.from_now)

    results = Task.search("elevator").to_a

    assert_includes results, by_title
    assert_includes results, by_description
    assert_equal 2, results.size
  end

  test "search treats SQL wildcards as literals" do
    Task.delete_all
    literal = Task.create!(user: users(:alice), title: "Discount is 0% this month", due_at: 1.day.from_now)
    Task.create!(user: users(:alice), title: "Other task", due_at: 1.day.from_now)

    assert_equal [ literal ], Task.search("0%").to_a
  end

  test "blank search returns everything" do
    assert_equal Task.count, Task.search("").count
    assert_equal Task.count, Task.search(nil).count
  end

  test "accepts allowed files within the size limit" do
    task = Task.new(user: users(:alice), title: "With attachments", due_at: 1.day.from_now)
    task.files.attach(io: file_fixture("sample.pdf").open, filename: "sample.pdf", content_type: "application/pdf")
    task.files.attach(io: StringIO.new("plain text"), filename: "note.txt", content_type: "text/plain")

    assert task.valid?
  end

  test "rejects files over 10 MB" do
    task = Task.new(user: users(:alice), title: "Big upload", due_at: 1.day.from_now)
    task.files.attach(io: StringIO.new("x" * (10.megabytes + 1)), filename: "big.pdf", content_type: "application/pdf")

    assert_not task.valid?
    assert_match(/too large/i, task.errors[:files].join(" "))
  end

  test "rejects disallowed content types" do
    task = Task.new(user: users(:alice), title: "Sketchy upload", due_at: 1.day.from_now)
    task.files.attach(io: StringIO.new("MZ fake exe"), filename: "virus.exe", content_type: "application/x-msdownload")

    assert_not task.valid?
    assert_match(/unsupported type/i, task.errors[:files].join(" "))
  end

  # Regression guard: Active Storage identifies the blob from its bytes, so a
  # renamed file with a faked Content-Type must still be rejected.
  test "rejects a file whose bytes do not match the declared type" do
    task = Task.new(user: users(:alice), title: "Spoofed upload", due_at: 1.day.from_now)
    task.files.attach(io: StringIO.new("MZ\x90\x00fake windows binary"), filename: "report.pdf", content_type: "application/pdf")

    assert_not task.valid?
    assert_match(/unsupported type/i, task.errors[:files].join(" "))
  end

  # Validation only looks at attachments added in the current save, so editing a
  # title does not re-read blobs that were already accepted and stored.
  test "attachments already stored are not re-checked on later saves" do
    task = Task.create!(user: users(:alice), title: "Has a file", due_at: 1.day.from_now)
    task.files.attach(io: file_fixture("sample.pdf").open, filename: "sample.pdf", content_type: "application/pdf")
    task.save!

    reloaded = Task.find(task.id)

    assert_empty reloaded.attachment_changes
    assert reloaded.update(title: "Renamed")
  end
end
