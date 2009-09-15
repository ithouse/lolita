module Extensions::TinyMceExtensions
  
  protected 
  
  def change_content obj
    obj||=""
    obj.gsub!(/src=\"\.\.\/\.\./,'src="');
    obj.gsub!(/\?\d{1,}\"/,'"');
    if !obj.match(/src=\"\//) && !obj.match(/src=\"http:/)
      obj.gsub!(/src=\"/,'src="/')
    end
    obj.gsub!(/src=\"\/\.\.\//,'src="/');
#    obj.gsub!(/href=\"\.\.\/\.\./,'href="');
#    obj.gsub!(/href=\"http:\/\/#{Lolita.config.domain}/,'href="')
#    obj.gsub!(/href=\"\/(\/|\w)+\"/){|match|
#      change_url(match)
#    }
#    obj.gsub!(/href=\"[c](\/|\w)+\"/){|match| #šis vecajam kad ir href="cms/sdfasdf"
#      change_url(match,true)
#    }
  end
  
  
  def change_url url,add=false
    new_url=""
    url.gsub!(/href=\"/,"")
    url.gsub!(/\"/,"")
    parts=url.split("/")
    if parts.last.to_i>0
      id=parts.last
      parts.pop #izmet id
    end
    parts.pop #izmet actionu parasti view
    urs=Admin::UrlScope.find_by_name(parts.last) #text_page, news utt
    md=MetaData.by_metaable id,parts.last
    if urs && md && md.url.to_s.size>0
      new_url+="/"+urs.scope
      new_url+="/"+md.url
    else
      new_url=(add ? "/" : "") + url
    end
    new_url='href="'+new_url+'"'
    new_url
  end
end
