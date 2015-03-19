RailsApp::Application.routes.draw do
  lolita_for :posts
  lolita_for :comments
  lolita_for :dashboard
  lolita_for :data_import
end
