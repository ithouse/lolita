class RequestMailer < ActionMailer::Base
   def mail(recipient,title,data,from=false)
    ActionMailer::Base.raise_delivery_errors = true
    @from =from || Lolita.config.default_from #title
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
end
