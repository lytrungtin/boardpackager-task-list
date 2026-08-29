class Task < ApplicationRecord
  # Optional while pre-auth rows exist; see AddUserToTasks migration note.
  belongs_to :user, optional: true

  # Attachments are stored via Active Storage (disk service in dev/test).
  # purge_later keeps request cycles fast; a background job deletes blobs.
  has_many_attached :files, dependent: :purge_later

  ALLOWED_CONTENT_TYPES = %w[image/png image/jpeg application/pdf text/plain].freeze
  MAX_FILE_SIZE = 10.megabytes

  validates :title, presence: true
  validates :due_at, presence: true
  validate :acceptable_files

  # Deliberately NOT validating that due_at is in the future: users may log
  # work that is already late, and overdue rendering needs past due dates.

  scope :ordered, -> { order(due_at: :asc) }
  scope :overdue, -> { where(completed_at: nil).where(due_at: ...Time.current) }
  # "Due by end of today" includes tasks that are already overdue — they are
  # still due by the end of today.
  scope :due_today, -> { where(due_at: ..Time.zone.now.end_of_day) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :active, -> { where(completed_at: nil) }

  # Wildcards typed by users (%_) are escaped so they match literally.
  # ILIKE keeps matching case-insensitive; it is PostgreSQL-specific, which
  # is acceptable because Postgres is the only database this app targets.
  scope :search, ->(query) {
    next all if query.blank?

    term = "%#{sanitize_sql_like(query.strip)}%"
    where("title ILIKE :term OR description ILIKE :term", term: term)
  }

  # completed_at doubles as the completion flag and the audit trail:
  # nil = open, timestamp = when the task was finished.
  def complete! = update!(completed_at: Time.current)

  def uncomplete! = update!(completed_at: nil)

  def completed? = completed_at.present?

  # due_at is required, but guard anyway: an unsaved record has no due_at and
  # rendering a status badge for one should not raise.
  def overdue? = !completed? && due_at.present? && due_at.past?

  private

    # Active Storage ships no built-in validations, so size and content type
    # are guarded manually.
    def acceptable_files
      newly_attached_blobs.each do |blob|
        if blob.byte_size > MAX_FILE_SIZE
          errors.add(:files, "#{blob.filename} is too large (max 10 MB)")
        end

        unless ALLOWED_CONTENT_TYPES.include?(blob.content_type)
          errors.add(:files, "#{blob.filename} has an unsupported type")
        end
      end
    end

    # Only the attachments being added in this save. The previous version walked
    # every attachment on every save, so editing a title re-checked blobs that
    # were already stored and accepted.
    #
    # Active Storage builds these blobs by running the bytes through Marcel, so
    # blob.content_type reflects what the file actually looks like rather than
    # only what the client claimed. Marcel still falls back to the declared type
    # when the bytes carry no recognisable signature; see the README.
    def newly_attached_blobs
      attachment_changes["files"]&.blobs || []
    end
end
