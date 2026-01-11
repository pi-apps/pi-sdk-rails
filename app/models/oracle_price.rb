class OraclePrice < ApplicationRecord
  self.table_name = 'oracle_prices'

  validates :pair, :rate, :source, presence: true
  validates :pair, uniqueness: true

  scope :latest, ->(pair) { where(pair: pair).order(updated_at: :desc).limit(1).first }
  scope :batch, ->(pairs) { where(pair: pairs).group_by(&:pair) }
  scope :stale, ->(age = 5.minutes) { where('updated_at < ?', age.ago) }

  def fresh?
    updated_at > 5.minutes.ago
  end

  def confidence_percentage
    (confidence * 100).round(2)
  end

  def age_seconds
    ((Time.current - updated_at) / 1.second).round
  end
end
