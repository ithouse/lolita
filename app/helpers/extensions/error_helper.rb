module Extensions::ErrorHelper

  def error_marker err_fields=[],field=nil
    err_fields.include?(field.to_sym) ? '<div class="err-marker">&nbsp;</div>' : ""
  end
  
  def get_object_errors(object_name)
    if object_name.is_a?(Hash) && object_name.size>0
      object_name
    else
      object = instance_variable_get("@#{object_name}")
      object.errors if object && object.respond_to?("errors") &&  !object.errors.empty?
    end
  end

  def has_error?(object_name,field)
    (get_object_errors(object_name)||[]).detect{|key,value| key.to_sym==field.to_sym} ? true : nil
  end

  def error_fields_for(object_name)
    (get_object_errors(object_name)||[]).collect{|key,value| key.to_sym}
  end

  def error_messages_for_cms(object_name)
    object_errors=get_object_errors(object_name)
    if object_errors
      errors="<div class='warnbox'>"+list_start_tags+
        "<div class='top'>"+image_tag("/lolita/images/cms/exclamation.gif",:alt=>"")+" #{object_errors.size>1 ? 'Atrastas' : 'Atrasta'} #{spell_number(object_errors.size,'f')} #{object_errors.size>1 ? t(:"simple words.errors") : t(:"simple words.error")}"+"</div>"+
        content_tag("ul",object_errors.collect { |key,error|
          name=field_title(key)
          if error.is_a?(Array) && error.size>1
            error[0]=t(error.first) if error.first.is_a?(Symbol)
            error_msg=error.first%error.last
          else
            if error.is_a?(Array)
              error_msg=error.first.is_a?(Symbol) ? t(error.first) : error.first
            else
              error_msg=error.is_a?(Symbol) ? t(error) : error
            end
          end
          msg1=name || ""
          msg2=error_msg || ""

          content_tag("li", "#{msg1} #{msg2}")
        })+
        list_end_tags+"</div><br class='clear' />"
    end
    (errors || "").html_safe!
  end
end