class SsoController < ApplicationController
  
  def verify
    begin
      #Atrod to portālu kurā reāli iet
      Admin::Token.current_token = Admin::Token.find_by_token(params[:id])
      #skatās vai jau nav bijis ieiets bāzes portālā
      if cookies[:sso_token] and existing_token = Admin::Token.find_by_token(cookies[:sso_token])
        if existing_token!=Admin::Token.current_token
          if existing_token.user_id.to_i>0
            Admin::Token.current_token.update_attributes!(:user_id=>existing_token.user_id)
          else
            existing_token.update_attributes!(:user_id=>Admin::Token.current_token.user_id) #lai vienmēr portālam būtu users ja tāds ir bijis
          end
        end
        Admin::Token.current_token = existing_token.adopt_params(Admin::Token.current_token)
      end
      Admin::Token.current_token.cleanup
      set_sso_cookie
      redirect_to "http://#{Admin::Token.current_token.portal.domain}#{request.port!=80 ? ":#{request.port}" : ""}" <<
        "/sso/recovery/#{ Admin::Token.current_token.user_id.to_i>0 ? Admin::Token.current_token.token : params[:id]}"
    rescue 
      redirect_to "http://#{Admin::Portal.find_by_root(true).domain}"
    end
  end

  def recovery
    session[:sso_verified] = true
    Admin::Token.current_token = Admin::Token.find_by_token(params[:id])
    set_sso_cookie
    if Admin::Token.current_token
      redirect_to Admin::Token.current_token.uri
    else
      redirect_to "/"
    end
  end

end
