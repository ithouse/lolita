# To change this template, choose Tools | Templates
# and open the template in the editor.

module Extensions::FormHelper
  def select_gender(object, method, options = {}, html_options = {})
    choices = [
      [t(:"gender.man"), 1],
      [t(:"gender.woman"), 2]
    ]
    current_obj=instance_variable_get("@#{object}")
    select_tag("#{object}[#{method}]",options_for_select(choices,current_obj.send(method)),options)
   # select(object, method, choices, options, html_options)
  end
end
