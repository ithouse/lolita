Lolita.setup do |config|
  #= More info about setup - https://github.com/ithouse/lolita/wiki/Lolita-setup
  #= More info about authentication - https://github.com/ithouse/lolita/wiki/Authorization-and-authentication

<% if defined?(Devise) && default_user_class = Devise.mappings.keys.first %>
  config.user_classes << <%= default_user_class.to_s.camelize %>
  config.authentication=:authenticate_<%= default_user_class %>!
<% else %>
  #= Sample config for Admin user managing Lolita
  # config.user_classes << Admin
  # config.authentication = :authenticate_admin!
<% end %>
  ## add this if you manage your authorization with CanCan
  # config.authorization = "CanCan"
end