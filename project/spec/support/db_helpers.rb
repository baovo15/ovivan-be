# spec/support/db_helpers.rb
module DbHelpers
  def reset_pk_sequence(table)
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      ActiveRecord::Base.connection.reset_pk_sequence!(table)
    end
  end
end

RSpec.configure do |config|
  config.include DbHelpers
end
