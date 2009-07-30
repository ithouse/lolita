class CreateAdminLanguages < ActiveRecord::Migration
  def self.up
    create_table :admin_languages do |t|
      t.integer :globalize_languages_id
      t.boolean :is_base_locale
    end
    insert("INSERT INTO admin_languages (globalize_languages_id,is_base_locale) VALUES(3435,1)")
    insert("INSERT INTO admin_languages (globalize_languages_id,is_base_locale) VALUES(1819,0)")
    insert("INSERT INTO admin_languages (globalize_languages_id,is_base_locale) VALUES(5556,0)")
  end

  def self.down
    drop_table :admin_languages
  end
end
