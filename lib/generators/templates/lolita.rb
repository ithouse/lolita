Lolita.setup do |config|
  #= More info about setup - https://github.com/ithouse/lolita/wiki/Lolita-setup
  #= More info about authentication - https://github.com/ithouse/lolita/wiki/Authorization-and-authentication
<% if defined?(Devise) && Devise.respond_to?(:mappings) && default_user_class = Devise.mappings.keys.first %>
  config.user_classes << <%= default_user_class.to_s.camelize %>
  config.authentication=:authenticate_<%= default_user_class %>!
<% else %>
  #= Sample config for Admin user managing Lolita
  # config.user_classes << Admin
  # config.authentication = :authenticate_admin!
<% end %>
  ## add this if you manage your authorization with CanCan
  # config.authorization = "CanCan"
  
  ## TinyMCE configuration - more see https://github.com/spohlenz/tinymce-rails#instructions
  # config.tinymce_configuration_set = :default
end
