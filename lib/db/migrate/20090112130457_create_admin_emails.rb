class CreateAdminEmails < ActiveRecord::Migration
  def self.up
    create_table :admin_emails do |t|
      t.string      :address
      t.references  :user
      t.timestamps
    end
  end

  def self.down
    drop_table :admin_emails
  end
end
