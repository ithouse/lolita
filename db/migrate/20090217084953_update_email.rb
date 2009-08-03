class UpdateEmail < ActiveRecord::Migration
  def self.up
    add_column :admin_emails, :status, :integer
  end

  def self.down
    remove_column :admin_emails, :status
  end
end
