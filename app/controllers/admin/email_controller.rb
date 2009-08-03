class Admin::EmailController < Managed
  allow Admin::Role.admin, :public=>[:register]

  def register
    flash(true)
    if request.post?
      begin
        Admin::Email.create!(:address=>params[:address])
        flash[:notice]=t :"admin_email.registration successful"
      rescue ActiveRecord::RecordInvalid
        flash[:error]=t :"admin_email.registration failed"
      end   
    end
    render :text=>"",:layout=>request.xml_http_request? ? false : "cms/register"
  end
  
  def filter
    current_name=params[:query].split(",").last
    result=params[:query].last!="," ?
      Admin::Email.starts_with(current_name).collect{|email| email.address}+
      Admin::Email.ends_with(current_name).collect{|email| email.address}+
      Admin::Email.in_address(current_name).collect{|email| email.address} :
      []
    render :text=>result.uniq.join("\t")
  end

  def add_remove_mail_to_session
    # session[:approved_emails]||=[]
    email=Admin::Email.find_by_id(params[:email_id])
    if email && !email.user
      if email.status.to_i==1
        email.status=0
      elsif email.status.to_i==0
        email.status=1
      end
      email.save!
      render :text=>email.status==0 ? t(:"admin_email.dont send") : t(:"admin_email.send")
    else
      render :text=>t(:"admin_email.has user")
    end
    
  end

  def send_invitations
    error=nil
    Admin::Email.find(:all,:conditions=>["admin_emails.status=?",1]).each{|email|
      body_data={}
      begin
        if email.user
          user=email.user
        else
          user=Admin::PublicUser.create_temp_user(email.id)
          body_data[:kods]={:title=>t(:"admin_email.registration code"),:value=>user.registration_code}
        end
        body_data[:header]=params[:subject].to_s.size>0 ? params[:subject] : t(:"admin_email.confirmation header")
        body_data[:welcome]={:title=>"",:value=>params[:text]}
        body_data[:zlink]={:title=>"URL",:value=>"http://#{Admin::Portal.find_by_root(true).domain}/register/#{user.registration_code}"}
        user.send_registration_email(body_data[:header],body_data)
        email.status=0
        email.save!
      rescue ActiveRecord::RecordInvalid
        error="#{email.address} #{t(:"ActiveRecord.errors.taken")}"
      end
    }
    error ? render(:text=>error,:status=>404,:layout=>false) : list
  end
  
  private

  def before_list
    if params[:status].to_i>0
      case params[:status].to_i
      when 1
        @config[:list][:conditions]=["admin_emails.user_id IS NULL"]
      when 2
        @config[:list][:joins]="INNER JOIN admin_users ON admin_users.id=admin_emails.user_id AND NOT admin_users.registration_code IS NULL"
      when 3
        @config[:list][:joins]="INNER JOIN admin_users ON admin_users.id=admin_emails.user_id AND admin_users.registration_code IS NULL"
      end
    end
  end
  def config
    {
      :tabs=>[
        {:type=>:content,:fields=>:default,:in_form=>true,:opened=>true}
      ],
      :list=>{
        :parent_filter=>"filter",
        :options=>[:edit,:destroy],
        :sort_column=>'address',
        :sort_direction=>'asc',
        :sortable=>true
      },
      :fields=>[
        {:type=>:text,:field=>:address,:html=>{:maxlength=>255},:actions=>[:update]},
        {:type=>:autocomplete,:field=>:address,:url=>{:controller=>"/admin/email",:action=>:filter},:save_method=>"emails=",:actions=>[:create]}
      ]
    }
  end
end
