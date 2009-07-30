class CreateAdminTokens < ActiveRecord::Migration
  def self.up
    create_table :admin_tokens do |t|
      t.references :user
      t.references :portal
      t.text       :uri
      t.string     :token,   :size=>80
      t.timestamps
    end
  end

  def self.down
    drop_table :admin_tokens
  end
end
