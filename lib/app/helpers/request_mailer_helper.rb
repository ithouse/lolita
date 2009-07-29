module RequestMailerHelper
  def e_mail_data data
    result=""
    if data[:body] && data[:body].is_a?(Array)
      data[:body].each{|value|
        result+=e_mail_data_value(value)+"\n"
      }
    else
      data.each{|key,value|
        result+=e_mail_data_value(value)+"\n"
      }
    end
    result
  end
  
  def e_mail_data_value value
    out=""
    if value.is_a? Hash 
      parts=value[:value].split("|") if value[:value] && !value[:value].is_a?(Time)
      if parts && parts.size>1
        out+="#{value[:title]}:"
        parts.each{|part|
          out+="              #{part}"
        }
      else
        out+=value[:title].to_s.size>0 ? "#{value[:title]}: " : ""
        out+="#{value[:value]}" 
      end
    end 
    out
  end
end