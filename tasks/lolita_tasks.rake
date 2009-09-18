namespace :lolita do
  desc "Setup lolita"
  task :setup do
    # Create static file link
    unless File.exists?("#{RAILS_ROOT}/public/lolita")
      FileUtils.ln_s("#{RAILS_ROOT}/vendor/plugins/lolita/_public/","#{RAILS_ROOT}/public/lolita")
      puts "[new] #{RAILS_ROOT}/public/lolita"
    end

    # copy lolita's YAML config file
    unless File.exists?("#{RAILS_ROOT}/config/lolita.yml")
      FileUtils.copy("#{RAILS_ROOT}/vendor/plugins/lolita/config/lolita.yml","#{RAILS_ROOT}/config/lolita.yml")
      puts "[new] config/lolita.yml"
    end

    # copy lolita's initializer
    unless File.exists?("#{RAILS_ROOT}/config/initializers/lolita_init.rb")
      FileUtils.copy("#{RAILS_ROOT}/vendor/plugins/lolita/config/initializers/lolita_init.rb","#{RAILS_ROOT}/config/initializers/lolita_init.rb")
      puts "[new] config/initializers/lolita_init.rb"
    end

    # create blank CSS file used by TinyMCE
    unless File.exists?("#{RAILS_ROOT}/public/stylesheets/tinymcestyle.css")
      File.open("#{RAILS_ROOT}/public/stylesheets/tinymcestyle.css", "w")
      puts "[new] public/stylesheets/tinymcestyle.css"
    end

    # Insert must have data into DB
    insert("INSERT INTO admin_users (login,email,crypted_password,salt,type) VALUES('admin','admin@example.com','78437eec8760ac08ad9cab98b6dfc516c31be062','f15c1dcd585628112cc4076f8dd31a877e342fce','Admin::SystemUser')")

    insert("INSERT INTO admin_roles (name,built_in) VALUES('administrators',1)")
    insert("INSERT INTO roles_users (user_id,role_id) VALUES(1,1)")

    insert("INSERT INTO admin_tables (name,human_name) VALUES('admin/user','Lietotāji')")
    insert("INSERT INTO admin_tables (name,human_name) VALUES('admin/role','Lomas')")
    insert("INSERT INTO admin_tables (name,human_name) VALUES('admin/access','Pieejas')")
    insert("INSERT INTO admin_tables (name,human_name) VALUES('admin/url_scope','Draudzīgie nosaukumi')")
    insert("INSERT INTO admin_tables (name,human_name) VALUES('admin/configuration','Konfigurācija')")
    insert("INSERT INTO admin_tables (name,human_name) VALUES('admin/table','Sadaļas')")
    insert("INSERT INTO admin_tables (name,human_name) VALUES('admin/field','Lauki')")
    insert("INSERT INTO admin_tables (name,human_name) VALUES('admin/menu','Izvēlne')")
    insert("INSERT INTO admin_tables (name,human_name) VALUES('admin/menu_item','Izvēļņu ieraksti')")

    insert("INSERT INTO menus (menu_name,menu_type,module_name,module_type) VALUES('Admin','app','admin','app')")
    insert("INSERT INTO menus (menu_name,menu_type,module_name,module_type) VALUES('Saturs','web','admin','web')")

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

    insert("INSERT INTO admin_languages (globalize_languages_id,is_base_locale) VALUES(3435,1)")
    insert("INSERT INTO admin_languages (globalize_languages_id,is_base_locale) VALUES(1819,0)")
    insert("INSERT INTO admin_languages (globalize_languages_id,is_base_locale) VALUES(5556,0)")
  end
end