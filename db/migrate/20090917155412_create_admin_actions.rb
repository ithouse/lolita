class CreateAdminActions < ActiveRecord::Migration
  def self.up
    create_table :admin_actions do |t|
      t.string :controller
      t.string :action
    end
  end

  def self.down
    drop_table :admin_actions
  end
end
