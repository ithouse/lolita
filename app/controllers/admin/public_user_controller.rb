class Admin::PublicUserController < Managed
  allow :public=>[:login,:logout,:register,:signup], :all_public=>[:show] #:all_public=>, :message

  def registration_confirmation #tiks izmantots kad nebūs vairs reģistrācijas laiks
    if user=Admin::PublicUser.register(params[:code])
      user.register
      register_user_in_session(user)
      if !Lolita.config.multi_domain_portal || is_local_request?
        redirect_authenticated_user
      end
    else
      redirect_back_or_default(:controller=>"/")
    end
  end
  
  def register
    if @user=Admin::PublicUser.register(params[:code])
      #register_user_in_session(@user)
      redirect_to :controller=>"/signup", :code=>params[:code]
    else
      redirect_back_or_default home_url
    end
  end
  
  def signup
    return redirect_authenticated_user if logged_in?

    @user=Admin::PublicUser.register(params[:code])
    flash[:error]=nil
    if request.post? && params[:user] 
      begin
        Admin::PublicUser.transaction do
          params[:profile]={:country_id=>params[:profile][:country_id]}
          params[:profile][:registration]=true
          if @user #jau eksistē vajag tikai pievienot datus
            @profile=Cms::Profile.new(params[:profile])
            @profile.save
            @user.registration=true
            @user.crypted_password=nil
            @user.update_attributes(params[:user])
            @user.register_profile(@profile) 
          else #izveido jaunu, bez reģistrācijas koda ja nāk, nākotnē
            @profile=Cms::Profile.new(params[:profile])
            @profile.save
            @user=Admin::PublicUser.new(params[:user])
            @user.registration=true
            @user.save
            @user.register_profile(@profile)
            unless HumanControl.check(params[:human_control])
              @user.errors.add("human_control",t(:"errors.wrong human control"))
            end
            @public_registration=true
          end
          if !@user.errors.empty? || !@profile.errors.empty?
            raise ActiveRecord::RecordNotSaved
          else
            @user.register!
          end
        end
        if @user.registered?
          register_user_in_session(@user)
          if !Lolita.config.multi_domain_portal || is_local_request?
            session[:return_to]=nil
            if params[:save]
              redirect_authenticated_user
            else
              redirect_to :action=>"profile"
            end
          end
        else
          send_registration_email @user,t(:"public_user.signup email subject"),t(:"public_user.signup email text")
          redirect_user
        end
      rescue ActiveRecord::RecordNotSaved
        flash[:error]=t(:"errors.all_fields_needed")
        render :layout=>layout_name()
      end
    else
      @user=Admin::PublicUser.register(params[:code]) #|| Admin::PublicUser.new(params[:user])
      if @user
        @profile=@user.profile || Cms::Profile.new(params[:profile])
        @user.login=nil
      else
        @profile=Cms::Profile.new(params[:profile])
      end
      render :layout=>layout_name
    end
  end

  def show
    @profile=Cms::Profile.find_by_id(params[:id])
    @user=@profile.user if @profile
    #    if @user.is_a?(Admin::SystemUser)
    #      redirect_authenticated_user
    #      return
    #    end
    if @profile && @user &&(( @user.is_a?(Admin::PublicUser) && @user.registered?) || (@user.is_a?(Admin::SystemUser)))
      render :layout=>layout_name
    else
      redirect_user
    end
  end

  def profile
    @user = current_user
    return redirect_authenticated_user unless system_user?

    params[:profile]=params[:profile].delete_if{|key,valu| key.to_sym==:user_id} if params[:profile].is_a?(Hash)
    @profile=Cms::Profile.find_by_user_id(@user.id) || Cms::Profile.new(params[:profile])
    flash[:notice]=nil
    if request.post? && params[:user]
      begin
        Admin::PublicUser.transaction do
          @user.update_attributes(params[:user])
          unless @profile.new_record?
            @profile.update_attributes(params[:profile])
          else
            @profile.save
          end
          if @profile.errors.empty? && @user.errors.empty?
            flash[:notice]=t(:"flash.saved")
          else
            flash[:error]=t(:"errors.cant_save").capitalize
          end
          if (params[:user][:old_password].to_s.size>0 && !Admin::PublicUser.authenticate(@user.login,params[:user][:old_password]))
            @user.errors.add(:old_password,t(:"errors.worng old password"))
          end
          if @user.valid? && @profile.valid?
            set_current_user @user
          else
            raise ActiveRecord::RecordNotSaved
          end
        end
      rescue ActiveRecord::RecordNotSaved
        
      end
    end
    render :layout=>request.xml_http_request? ? false : layout_name
  end

  #  def message
  #    if request.post? && params[:user_message] && !(params[:user_message][:subject].empty? && params[:user_message][:content].empty?)
  #      body_data={
  #        :header=>params[:user_message][:subject],
  #        :body=>[]
  #      }
  #      sender = "\"#{Admin::User.current_user.login}\" <#{Admin::User.current_user.email}>"
  #      body_data[:body]<<{:title=>"from",:value=>sender}
  #      body_data[:body]<<{:title=>"content",:value=>params[:user_message][:content]}
  #      RequestMailer::deliver_mail("valdis@ithouse.lv","#{body_data[:header]}",body_data)
  #      flash[:notice]=:"profile.message.thank you"
  #    end
  #    render :layout=>request.xml_http_request? ? false : "cms/public"
  #  end

  def login
    flash[:error]=nil
    if request.post?
      if user = Admin::PublicUser.authenticate(params[:login], params[:password])
        remember_me(user)
        register_user_in_session(user)
        if !Lolita.config.multi_domain_portal || is_local_request?
          redirect_authenticated_user
        end
      else
        flash[:error]={:login=>t(:"errors.unknown_public_user")} if params[:password] && params[:login]
        redirect_user
      end
    else 
      if Admin::User.access_to_area?(session)
        redirect_authenticated_user
      else
        redirect_user
      end
    end
  end

  def logout
    if ogged_in?
      reset_sso if Lolita.config.multi_domain_portal
      reset_remember_me
      reset_session
      flash[:notice] = t(:"flash.logout success")
    end
    redirect_to home_url
  end
  private

  def remember_me(user)
    cookies.delete :remember_me unless user.remember_token
    domain=request.domain()
    if params[:remember_me] && !user.remember_token
      user.update_attributes!(:remember_token=>Digest::SHA1.hexdigest("$$#{Time.now.to_s}$$#{params[:login]}$$"))
      cookies[:remember_me]={:value=>user.remember_token,:expires=>7.days.from_now,:domain=>domain}
    elsif user.remember_token
      cookies[:remember_me]={:value=>user.remember_token,:expires=>7.days.from_now,:domain=>domain}
    end
  end
  
  def reset_remember_me
    current_user.update_attributes!(:remember_token=>nil) if public_user? && current_user.remember_token
    cookies.delete(:remember_me)
  end

  def reset_sso #lai varētu šeit ielik vēl ko ja vajadzēs
    Admin::Token.destroy_all(["user_id=? OR updated_at<?",current_user.id,1.day.ago]) if Lolita.config.multi_domain_portal && !is_local_request?
    cookies.delete(:sso_token)
  end
  
  def send_registration_email user,header,text
    body_data={}
    body_data[:kods]={:title=>t(:"admin_email.registration code"),:value=>user.registration_code}
    body_data[:header]=header.to_s>0 ? header : t(:"admin_email.confirmation header")
    body_data[:link]={:title=>"URL",:value=>"http://telegraf.ithouse.lv/registration_confirmation/#{user.registration_code}"}
    body_data[:welcome]={:title=>"",:value=>text}
    user.send_registration_email(body_data[:header],body_data)
  end
  
  def register_user_in_session user
    session.data.delete(:user)
    set_current_user user
    if Lolita.config.multi_domain_portal && !is_local_request?
      token=Admin::Token.find_by_token(cookies[:sso_token])
      if token
        token.update_attributes!(:user=>user,:uri=>url_for(session[:return_to]) || home_url)
      end
      redirect_to "http://#{Admin::Portal.find_by_root(true).domain}#{request.port!=80 ? ":#{request.port}" : ""}" <<
        "/sso/verify/#{cookies[:sso_token]}"
    end
  end

  def redirect_authenticated_user
    if request.xml_http_request?
      render :text=>"[true]"
    else
      redirect_back_or_default(home_url) and return
    end
  end

  def redirect_user
    if request.xml_http_request?
      redirect_to home_url
    else
      redirect_to home_url
    end
  end

  def after_open
    @profile=@object.profile || Cms::Profile.new
  end

  def before_save
    @profile=Cms::Profile.find_by_id(my_params[:profile][:id]) || Cms::Profile.new
  end
  
  def after_save
    # @profile=Cms::Profile.find_by_id(my_params[:profile][:id])
    my_params[:profile].delete(:id)
    unless @profile
      @profile=Cms::Profile.new(my_params[:profile])
      @profile.save
    else
      @profile.update_attributes(my_params[:profile])
    end
    unless @profile.errors.empty?
      raise ActiveRecord::RecordNotSaved
    end
    @object.register_profile(@profile)
  end

  def on_save_error
    if !@object.errors.empty? || !@profile.errors.empty?
      merge_errors @object,@profile
    end
  end
  
  def config
    {
      :tabs=>[
        {:type=>:content,:in_form=>true,:opened=>true,:fields=>:default},
        {:type=>:default,:in_form=>true,:object=>:profile,:title=>t(:"profile.title"),:fields=>[
            {:type=>:hidden, :field=>:id},
            {:type=>:text,:field=>:first_name, :html=>{:maxlength=>255}},
            {:type=>:select,:field=>:country_id,:table=>"Cms::Country"},
            {:type=>:select,:field=>:district_id,:table=>"Cms::District",:include_blank=>true},
            {:type=>:select,:field=>:sex,:simple=>true,:options=>[[t(:"gender.man"),1],[t(:"gender.woman"),2]]},
            {:type=>:date,:field=>:birth_date,:config=>{:minute_step=>55,:start_year=>1910,
                :order=>[:day,:month,:year],:use_month_names=>month_names}
            },
            {:type=>:text,:field=>:blog_url},
            {:type=>:text,:field=>:home_page_url},
            {:type=>:textarea,:field=>:interests, :html=>{:class=>"small-textarea"}},
            {:type=>:text,:field=>:email, :html=>{:maxlength=>255}},
            {:type=>:text,:field=>:email_for_comments, :html=>{:maxlength=>255}},
            {:type=>:text,:field=>:ocupation, :html=>{:maxlength=>255}},
            {:type=>:checkbox,:field=>:hide},
          ]}
      ],
      :list=>{
        :conditions=>["admin_users.registration_code IS NULL"],
        :sortable=>true,
        :sort_column=>"login",
        :sort_direction=>"asc",
        :per_page=>100,
        :options=>[:edit,:destroy]
      },
      :fields=>[
        {:type=>:text,:field=>:login,:html=>{:maxlength=>255}},
        {:type=>:text,:field=>:email,:html=>{:maxlength=>255}},
        {:type=>:password,:field=>:password,:html=>{:maxlength=>40}},
        {:type=>:password,:field=>:password_confirmation,:html=>{:maxlength=>40}}
      ]
      
    }
  end
end
