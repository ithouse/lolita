class AdviceController < ApplicationController
  allow :all=>[:send_advice]
  access_control :include=>[:send_advice], :redirect_to=>{:action=>"send_advice"}

  def send_advice
    @errors={}
    @object={}
    if request.post?
      data=params[:object]
      fields={:text=>t(:"advice.description")}
      [:text].each{|key|
        @object[key]=data[key]
      }
      fields.each{|key,value|
        unless data[key] && data[key].size>0
          @errors[value]=[" #{t(:"ActiveRecord.errors.empty")}",nil]
        end
      }
      if @errors.empty?
        body_data={
          :header=>"#{Lolita.config.system :cms_title} #{t(:"simple words.advice")}",
          :body=>[]
        }
        body_data[:body]<<{:title=>t(:"advice.description"),:value=>data[:text]}
        body_data[:body]<<{:title=>t(:"advice.sender"),:value=>data[:submitter]}
        email_sent(Lolita.config.email(:bugs_to),body_data[:header],body_data)
      end
    end
    if @errors.empty? && request.post?
      redirect_to Lolita.config.system(:start_page_url)
    else
      render :layout=>"cms/simple"
    end
  end

  private

  def email_sent (email,title,data)
    RequestMailer::deliver_mail(email,"#{title}",data)
  end
end
