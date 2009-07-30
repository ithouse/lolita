class AddAdminTokensIndex < ActiveRecord::Migration
  def self.up
    add_index :admin_tokens, :token
    add_index :admin_tokens, :user_id
  end

  def self.down
    remove_index :admin_tokens, :column=>:token
    remove_index :admin_tokens, :column=>:user_id
  end
end
