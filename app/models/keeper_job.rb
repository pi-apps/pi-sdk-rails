class KeeperJob < ApplicationRecord
  self.table_name = 'keeper_jobs'

  enum status: { pending: 0, active: 1, paused: 2, completed: 3, failed: 4 }

  validates :name, :contract_address, :function_selector, presence: true

  scope :active, -> { where(status: :active) }
  scope :due, -> { where('next_execution <= ?', Time.current) }

  def execute!
    self.update(last_execution: Time.current, execution_count: execution_count + 1)
    ProcessKeeperUpkeepJob.perform_later(id)
  end

  def success_rate
    return 0 if execution_count.zero?
    (success_count.to_f / execution_count * 100).round(2)
  end

  def schedule_next
    interval_seconds = repeat_interval_seconds || 3600
    update(next_execution: Time.current + interval_seconds.seconds)
  end
end
