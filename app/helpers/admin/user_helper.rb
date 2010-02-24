module Admin::UserHelper
  def is_active_user
    yield if @active_user
  end
end
