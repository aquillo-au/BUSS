class ResetPrimaryKeySequences < ActiveRecord::Migration[8.1]
  def up
    return unless ActiveRecord::Base.connection.adapter_name == "PostgreSQL"

    %w[facebook_posts incidents notes people sign_ins users].each do |table|
      ActiveRecord::Base.connection.reset_pk_sequence!(table)
    end
  end

  def down
    # Sequences cannot be meaningfully reversed
  end
end
