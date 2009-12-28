# Helper methods for human control.
module Extensions::HumanControlHelper
  # Deprecated
  def human_control name=nil
    hc= HumanControl.image
    content_tag('div',
      hidden_field_tag((name ? "#{name}[human_control][picture_id]" : 'human_control[picture_id]'),hc.picture_id)+
      image_tag(hc.picture,:alt=>"")+
      text_field_tag((name ? "#{name}[human_control][answer]" : 'human_control[answer]'),nil,:size=>6,:maxlegth=>6),
    :class=>"human-control-container").html_safe!
  end
end
