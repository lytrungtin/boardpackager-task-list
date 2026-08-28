class AddUserDueIndexToTasks < ActiveRecord::Migration[8.1]
  def change
    add_index :tasks, [ :user_id, :due_at ]
    remove_index :tasks, :due_at
  end
end
