# coding: utf-8
# Include useful error handling method for Lolita forms and views and error list
# generator method for Lolita forms.
module Extensions::ErrorHelper

  # Return empty *DIV* tag with class <i>err-marker</i> if object errors has error
  # in given field.
  # ====Example
  #    error_marker(@object.errors,:name)
  def error_marker err_fields=[],field=nil
    err_fields.include?(field.to_sym) ? '<div class="err-marker">&nbsp;</div>' : ""
  end

  # Return error for object, allow error be passed or _object_ named.
  # ====Example
  #     # Return @user errors
  #     get_object_errors(:user)
  #
  #     # Return errors itself.
  #     get_object_errors(@user.errors)
  def get_object_errors(object_name)
    if object_name.is_a?(Hash) && object_name.size>0
      object_name
    else
      object = instance_variable_get("@#{object_name}")
      object.errors if object && object.respond_to?("errors") &&  !object.errors.empty?
    end
  end

  # Detect if _object_ errors or collection of errors include error for given +field+.
  # ====Example
  #     @user.errors.add(:name, "Not good name")
  #     # In views or helpers
  #     has_error?(:user,:name) # => true
  def has_error?(object_name,field)
    (get_object_errors(object_name)||[]).detect{|key,value| key.to_sym==field.to_sym} ? true : nil
  end

  # Return Array containing all _object_ errors fields.
  # ====Example
  #     # When user name is not correct
  #     error_fields_for(:user) #=> [:name]
  def error_fields_for(object_name)
    (get_object_errors(object_name)||[]).collect{|key,value| key.to_sym}
  end

  # Generate and return HTML of _object_ errors. Is used in Lolita forms because of
  # sepcial structure and classes used in HTML.
  def error_messages_for_cms(object_name)
    object_errors=get_object_errors(object_name)
    if object_errors
      errors="<div class='warnbox'>"+list_start_tags+
        "<div class='top'>"+image_tag("/lolita/images/cms/exclamation.gif",:alt=>"")+" #{object_errors.size>1 ? 'Atrastas' : 'Atrasta'} #{spell_number(object_errors.size,'f')} #{object_errors.size>1 ? t(:"simple words.errors") : t(:"simple words.error")}"+"</div>"+
        content_tag("ul",object_errors.collect { |key,error|
          object = instance_variable_get("@#{object_name}")
          name=object.class.human_attribute_name(key)
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

          content_tag("li", "\"#{msg1}\" #{msg2}")
        })+
        list_end_tags+"</div><br class='clear' />"
    end
    (errors || "").html_safe!
  end
end