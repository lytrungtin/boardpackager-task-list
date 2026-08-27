class Task < ApplicationRecord
  validates :title, presence: true
  validates :due_at, presence: true

  # Deliberately NOT validating that due_at is in the future: users may log
  # work that is already late, and overdue rendering needs past due dates.

  # completed_at doubles as the completion flag and the audit trail:
  # nil = open, timestamp = when the task was finished.
  def complete! = update!(completed_at: Time.current)

  def uncomplete! = update!(completed_at: nil)

  def completed? = completed_at.present?
end
