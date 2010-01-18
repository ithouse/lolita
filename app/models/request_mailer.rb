class RequestMailer < ActionMailer::Base
   def mail(recipient,title,data,from=false)
    ActionMailer::Base.raise_delivery_errors = true
    @from =from || Lolita.config.email(:default_from) #title
    @recipients=recipient
    @subject =title
    @body={:recipient => title,:data=>data}
#    if with_attachment
#      f=FileItem.find(with_attachment)
#      file=File.open(RAILS_ROOT+'/public'+f.name.url,"rb")
#      attachment(:content_type => "application/msword",
#        :filename => "cv.doc",
#        :body => file.read)
#      file.close
#      f.destroy()
#      FileItem.delete(with_attachment)
#    end
  end

  def bug options = {}
    recipients Lolita.config.email(:bugs_to)
    from Lolita.config.email(:bugs_from)
    subject "Bug from #{options[:request].host_with_port}"
    sent_on Time.now
    body({
        :title => options[:title] || "",
        :msg => options[:msg] || "",
        :request => options[:request],
        :params => options[:params],
        :session => options[:session]
    })
    content_type "text/html"
  end

  def forgot_password email,options={}
    recipients email
    from Lolita.config.email(:default_from)
    subject "#{I18n.t(:"system_user.form.title")} #{Lolita.config.system :cms_title}"
    sent_on Time.now
    body({
        :id=>options[:user].reseted_password_hash,
        :host=>options[:host]
    })
    content_type "text/html"
  end
end
