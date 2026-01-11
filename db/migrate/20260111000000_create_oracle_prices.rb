class CreateOraclePrices < ActiveRecord::Migration[6.1]
  def change
    create_table :oracle_prices do |t|
      t.string :pair, null: false
      t.decimal :rate, precision: 18, scale: 8
      t.integer :timestamp
      t.decimal :confidence, default: 95.0
      t.integer :nodes, default: 0
      t.string :source, default: 'chainlink'
      t.datetime :last_update

      t.timestamps
    end

    add_index :oracle_prices, :pair, unique: true
  end
end
