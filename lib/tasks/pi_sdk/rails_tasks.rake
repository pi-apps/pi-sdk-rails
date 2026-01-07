namespace :pi_sdk do
  desc 'List all PiTransactions'
  task pi_transactions: :environment do
    if Object.const_defined?("PiTransaction")
      puts "\nID |          payment_id         | state | user_id | order_id | created_at"
      puts '-' * 60
      ::PiTransaction.all.find_each do |tx|
        puts [tx.id,
              tx.payment_id, tx.state,
              tx.respond_to?(:user_id) ? tx.user_id : nil,
              tx.respond_to?(:order_id) ? tx.order_id : nil,
              tx.created_at].join(' | ')
      end
      puts
    else
      puts "PiTransaction model not defined. Make sure you have run the generator and migrated your database."
    end
  end

  desc 'List all Pi Users (as referenced by PiTransaction::USER_CLASS)'
  task users: :environment do
    unless Object.const_defined?("PiTransaction") && ::PiTransaction.const_defined?("USER_CLASS")
      puts "PiTransaction or USER_CLASS not defined. Make sure models and generator/migrations are set up."
      next
    end
    user_class = ::PiTransaction::USER_CLASS
    unless user_class.column_names.include?("pi_username")
      puts "User class '#{user_class}' does not have a 'pi_username' column."
      next
    end
    puts "\nID | pi_username | created_at"
    puts '-' * 60
    user_class.all.find_each do |user|
      puts [user.id, user.respond_to?(:pi_username) ? user.pi_username : nil, user.created_at].join(' | ')
    end
    puts
  end
end
