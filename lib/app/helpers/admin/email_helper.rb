module Admin::EmailHelper
  def add_to_session_link email
    config={
      :controller=>"/admin/email",
      :action=>:add_remove_mail_to_session,
      :params=>{:email_id=>email.id},
      :loading=>false,
      :before=>%(add_very_small_loading(object,"span")),
      :on_complete=>"request.argument.object.innerHTML=request.responseText"
    }
    if email.user
      email.user.registration_code ? t(:"admin_email.has user") : t(:"admin_email.is registered")
    elsif email.status==0
      cms_link t(:"admin_email.dont send"),config
    else
      cms_link t(:"admin_email.send"),config
    end
  end

  def email_filter_options
    options_for_select [
      [t(:"notice.not_followed"),0],
      [t(:"admin_email.logged"),1],
      [t(:"admin_email.has user"),2],
      [t(:"admin_email.is registered"),3]
    ], params[:status].to_i

  end
end
