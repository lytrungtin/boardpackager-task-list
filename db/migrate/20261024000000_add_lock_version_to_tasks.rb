class AddLockVersionToTasks < ActiveRecord::Migration[8.1]
  def change
    # Optimistic locking: hai tab cùng sửa một task thì lần lưu sau
    # nhận StaleObjectError thay vì ghi đè im lặng.
    add_column :tasks, :lock_version, :integer, null: false, default: 0
  end
end
