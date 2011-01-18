class DeviseCreateLolitaAdmins < ActiveRecord::Migration
  def self.up
    create_table(:lolita_admins) do |t|
      t.database_authenticatable :null => false
      t.recoverable
      t.rememberable
      t.trackable

      # t.confirmable
      # t.lockable :lock_strategy => :failed_attempts, :unlock_strategy => :both
      # t.token_authenticatable

      t.timestamps
    end

    add_index :lolita_admins, :email,                :unique => true
    add_index :lolita_admins, :reset_password_token, :unique => true
    # add_index :admins, :confirmation_token,   :unique => true
    # add_index :admins, :unlock_token,         :unique => true
  end

  def self.down
    drop_table :lolita_admins
  end
end
