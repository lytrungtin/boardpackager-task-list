class Task < ApplicationRecord
  validates :title, presence: true
  validates :due_at, presence: true

  # Deliberately NOT validating that due_at is in the future: users may log
  # work that is already late, and overdue rendering needs past due dates.

  scope :ordered, -> { order(due_at: :asc) }
  scope :overdue, -> { where(completed_at: nil).where(due_at: ...Time.current) }
  # "Due by end of today" includes tasks that are already overdue — they are
  # still due by the end of today.
  scope :due_today, -> { where(due_at: ..Time.zone.now.end_of_day) }

  # completed_at doubles as the completion flag and the audit trail:
  # nil = open, timestamp = when the task was finished.
  def complete! = update!(completed_at: Time.current)

  def uncomplete! = update!(completed_at: nil)

  def completed? = completed_at.present?

  def overdue? = !completed? && due_at.past?
end
