module Admin::UserHelper
  include Extensions::PossibleActionsHelper
  def is_active_user
    yield if @active_user
  end
end
