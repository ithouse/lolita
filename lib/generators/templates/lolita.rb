
Lolita.setup do |config|
  # ==> User and authentication configuration
  # Add one or more of your user classes to Lolita
  # config.user_classes << MyUser
  # config.authentication = :authenticate_user!
  
  # Define authentication for Lolita controllers.
  # Call some of your own methods
  # config.authentication=:is_admin?
  # Or use some customized logic
  # config.authentication={
  #  current_user.is_a?(Admin) || current_user.has_role?(:admin)
  # }

  <% if defined?(Devise) %>
    <% default_user_class = Devise.mappings.keys.first %>
    config.user_classes << <%= default_user.to_s.camelize %>
    config.authentication=:authenticate_<%= default_user_class %>!
  <% end %>
end
