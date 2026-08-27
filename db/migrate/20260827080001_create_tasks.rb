class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.datetime :due_at, null: false
      t.datetime :completed_at

      t.timestamps
    end

    add_index :tasks, :due_at
  end
end
