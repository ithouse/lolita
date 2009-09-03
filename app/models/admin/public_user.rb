class Admin::PublicUser < Admin::User
  set_table_name :admin_users
  attr_accessor :temp_user
  attr_accessor :registration
  attr_accessor :privacy
  attr_accessor :terms_of_service
  attr_protected :registration_code
  before_create :create_registration_code
  validates_length_of       :password, :within => 6..40, :if => :password_required?
  validates_presence_of :terms_of_service, :if=>:registration?
  validates_presence_of :privacy, :if=>:registration?

  def total_comments_rating
    Cms::Comment.sum(:total_votes,:conditions=>["user_id=?",self.id])
  end

  def self.authenticate(login, password)
    user = self.find_by_login(login)
    good=user && !user.deleted && user.authenticated?(password)   ? user : nil
    unless good
      if Lolita.config.allow :system_in_public
        Admin::SystemUser.authenticate(login,password)
      end
    else
      good
    end
  end

  def self.register code
    self.find_by_registration_code(code) if code.to_s.size==8
  end

  def register!
    self.registration_code=nil
    self.save #bez !, jo manuāli pārbaudu vai vajag raisot
  end

  def registered?
    self.registration_code.nil?
  end

  def self.create_temp_user email
    temp_p=self.temp_password(16)
    if email.is_a?(Integer)
      email_address=Admin::Email.find_by_id(email)
      email=email_address.address if email_address
    else
      email_address=Admin::Email.create!(:address=>email) unless Admin::Email.find_by_address(email)
    end
    self.create!(:login=>temp_p,:password=>temp_p,:password_confirmation=>temp_p,:email=>email,:email_address=>email_address,:temp_user=>true)
  end

  def send_registration_email header,body_data={}
    RequestMailer::deliver_mail(self.email,header,body_data)
  end
  
  def is_real_user?
    real_user=Admin::PublicUser.find_by_login(self.login)
    real_user==self
  end

  private

  def registration?
    self.registration
  end
  
  def create_registration_code
    if self.temp_user
      temp=Admin::User.temp_password(8)
      while Admin::PublicUser.find_by_registration_code(temp)
        temp=Admin::User.temp_password(8)
      end
      self.registration_code=temp
    end
  end
end