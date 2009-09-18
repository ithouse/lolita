class CreateAdminLanguages < ActiveRecord::Migration
  def self.up
    create_table :admin_languages do |t|
      t.integer :globalize_languages_id
      t.boolean :is_base_locale
    end
  end

  def self.down
    drop_table :admin_languages
  end
end
