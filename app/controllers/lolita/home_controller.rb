class Lolita::HomeController < ApplicationController
  include Lolita::Controllers::UserHelpers
  before_filter :authenticate_lolita_user!
  layout "lolita/layouts/application"

  
end
