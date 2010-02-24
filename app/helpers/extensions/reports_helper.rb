# coding:utf-8
module Extensions::ReportsHelper
  def report_menu config, options={}
    content_tag("div",
      "Save data:"+
      report_links(config,options),
    :class=>"fr")
  end
  
  def report_links config,options={}
    result=""
    options.each{|type,configuration|
      result<<link_to(image_tag("/lolita/images/icons/#{type}.gif",:alt=>""),{:action=>"report", type.to_sym=>true},{:style=>"margin-right:2px;",:method=>:post})
    }
    result
  end
end
