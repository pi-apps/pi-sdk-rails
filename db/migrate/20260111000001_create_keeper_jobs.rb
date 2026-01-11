class CreateKeeperJobs < ActiveRecord::Migration[6.1]
  def change
    create_table :keeper_jobs do |t|
      t.string :name, null: false
      t.string :contract_address, null: false
      t.string :function_selector, null: false
      t.integer :status, default: 0
      t.integer :repeat_interval_seconds
      t.datetime :next_execution
      t.datetime :last_execution
      t.integer :execution_count, default: 0
      t.integer :success_count, default: 0
      t.string :last_error

      t.timestamps
    end

    add_index :keeper_jobs, :status
    add_index :keeper_jobs, :next_execution
  end
end
