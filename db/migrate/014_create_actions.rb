class CreateActions < ActiveRecord::Migration
  def self.up
    create_table :admin_actions do |t|
      t.string :controller
      t.string :action
    end
    insert("INSERT INTO admin_actions (controller,action) VALUES('/admin/user','list')")
    insert("INSERT INTO admin_actions (controller,action) VALUES('/admin/role','list')")
    insert("INSERT INTO admin_actions (controller,action) VALUES('/admin/access','list')")
    insert("INSERT INTO admin_actions (controller,action) VALUES('/admin/table','list')")
    insert("INSERT INTO admin_actions (controller,action) VALUES('/admin/field','list')")
    insert("INSERT INTO admin_actions (controller,action) VALUES('/admin/configuration','list')")
    insert("INSERT INTO admin_actions (controller,action) VALUES('/admin/user','signup')")
    insert("INSERT INTO admin_actions (controller,action) VALUES('/admin/role','create')")
    insert("INSERT INTO admin_actions (controller,action) VALUES('/admin/url_scope','list')")
    insert("INSERT INTO admin_actions (controller,action) VALUES('/admin/translate','list')") if Lolita.config.translation
  end

  def self.down
    drop_table :admin_actions
  end
end
