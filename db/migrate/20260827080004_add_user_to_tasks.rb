class AddUserToTasks < ActiveRecord::Migration[8.1]
  def change
    # Nullable on purpose: tasks created before authentication existed stay
    # valid. With more time: backfill to a default user, then tighten to
    # null: false in a follow-up migration.
    add_reference :tasks, :user, null: true, foreign_key: true
  end
end
