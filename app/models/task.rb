class Task < ApplicationRecord
  validates :title, presence: true
  validates :due_at, presence: true

  # Deliberately NOT validating that due_at is in the future: users may log
  # work that is already late, and overdue rendering needs past due dates.
end
