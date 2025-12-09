require 'rails/generators'

module Pinetwork
  class PiTransactionGenerator < ::Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)
    argument :order, type: :string, default: 'order', banner: 'order:ORDER_CLASS'
    argument :user,  type: :string, default: 'user',  banner: 'user:USER_CLASS'

    desc "Generates a PiTransaction model referencing your order and user classes, with all engine-required attributes."

    def add_pi_username_and_index_to_user
      # Pluralize the table name as Rails does for ActiveRecord
      user_table = user.to_s.pluralize.underscore
      migration_name = "add_pi_username_to_#{user_table}"
      # Generate the migration to add pi_username:string and a unique index
      generate("migration", "#{migration_name} pi_username:string:uniq")
    end

    # invoke after primary model/migration generation
    def create_pi_transaction_model
      say_status :invoke, "Generating PiTransaction model...", :green
      fields = [
        "#{user}:references",
        "#{order}:references",
        "amount:decimal",
        "memo:string",
        "state:string",
        "payment_id:string",
        "txid:string",
        "metadata:json"
      ]
      invoke_args = ["PiTransaction"] + fields
      ::Rails::Generators.invoke("active_record:model", invoke_args, behavior: behavior)
      remove_foreign_key_constraints # call here!
      add_pi_username_and_index_to_user # call new method after generating models/migrations
    end

    def inject_concern_into_model
      inject_into_class "app/models/pi_transaction.rb", "PiTransaction" do
        "  include Pinetwork::Rails::PiTransactionBehavior\n"
      end

      model_file = "app/models/pi_transaction.rb"
      if File.exist?(model_file)
        contents = File.read(model_file)
        # Insert class constants if not present
        unless contents.include?("ORDER_KEY_NAME") && contents.include?("USER_KEY_NAME") && contents.include?("USER_CLASS") && contents.include?("ORDER_CLASS")
          class_declaration_index = contents.index("class PiTransaction")
          if class_declaration_index
            # Guess Rails conventions for class names
            user_class_str = user.camelize
            order_class_str = order.camelize
            insert_after = contents.index("\n", class_declaration_index)
            consts = "  ORDER_KEY_NAME = :#{order}_id\n" +
                     "  USER_KEY_NAME  = :#{user}_id\n" +
                     "  ORDER_CLASS    = ::#{order_class_str}\n" +
                     "  USER_CLASS     = ::#{user_class_str}\n"
            contents = contents.dup.insert(insert_after + 1, consts)
          end
        end
        # Existing optional: true patch for belongs_to
        user_line = "belongs_to :#{user}"
        order_line = "belongs_to :#{order}"
        changed = false

        if contents.include?(user_line) && !contents.include?("#{user_line}, optional: true")
          contents.gsub!(/(belongs_to :#{user})(\b[^\n]*)?$/) { |match| match.include?('optional:') ? match : "#{match}, optional: true" }
          changed = true
        elsif !contents.include?(user_line)
          insert_index = contents.lines.find_index { |l| l =~ /include / } || 0
          lines = contents.lines
          lines.insert(insert_index + 1, "  belongs_to :#{user}, optional: true\n")
          contents = lines.join
          changed = true
        end

        if contents.include?(order_line) && !contents.include?("#{order_line}, optional: true")
          contents.gsub!(/(belongs_to :#{order})(\b[^\n]*)?$/) { |match| match.include?('optional:') ? match : "#{match}, optional: true" }
          changed = true
        elsif !contents.include?(order_line)
          insert_index = contents.lines.find_index { |l| l =~ /include / } || 0
          lines = contents.lines
          lines.insert(insert_index + 2, "  belongs_to :#{order}, optional: true\n")
          contents = lines.join
          changed = true
        end
        File.write(model_file, contents) if changed || !contents.include?("ORDER_KEY_NAME") || !contents.include?("ORDER_CLASS")
      end
    end

    # Re-add the migration edit step to ensure correct references
    def remove_foreign_key_constraints
      migration_file = Dir.glob("db/migrate/*_create_pi_transactions.rb").max_by { |f| File.mtime(f) }
      return unless migration_file && File.exist?(migration_file)
      contents = File.read(migration_file)
      contents.gsub!(/t\.references +:#{user}(,\s*.*)?$/) do |line|
        line = line.include?('foreign_key:') ? line.sub(/foreign_key: ?true/, 'foreign_key: false') : line.chomp + ', foreign_key: false'
        line = line.include?('null:') ? line.sub(/null: ?false/, 'null: true') : line.chomp + ', null: true'
        line
      end
      contents.gsub!(/t\.references +:#{order}(,\s*.*)?$/) do |line|
        line = line.include?('foreign_key:') ? line.sub(/foreign_key: ?true/, 'foreign_key: false') : line.chomp + ', foreign_key: false'
        line = line.include?('null:') ? line.sub(/null: ?false/, 'null: true') : line.chomp + ', null: true'
        line
      end
      File.write(migration_file, contents)
    end

    def remind_user_to_migrate
      say "\n[PiTransaction] Migration created. You should run: rails db:migrate", :yellow
    end
  end
end
