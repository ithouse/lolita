module KriminalHelper

  def kriminal_public_page_title
    
    md=if params[:controller]=="cms/comment"
      MetaData.by_metaable get_id(:news_id,"cms/news"),"cms/news"
    else
      MetaData.by_metaable get_id,params[:controller]
    end
    md=Admin::Menu.best_menu_item_for_params(params) unless md
    if md && title=md.title
      title=telegraf_public_page_title(title)
    elsif md
      title=telegraf_public_page_title()
    end
    title || Admin::Configuration.get_value_by_name("kriminal_title") || t(:"configuration.default page title")

  end
  #  <% kriminal_annex_categories(k_category) do |c,portal| %>
  #        <li>
  #          <% if portal %>
  #            <a href="http://<%=portal.domain%>"><%=c.name.chars.capitalize%></a>
  #          <% else %>
  #            <%= link_to c.name.chars.capitalize, category_url(get_id(c)) %>
  #          <% end %>
  #        </li>
  #      <% end %>
  def main_kriminal_news
    @latest_news=Cms::News.latest(3,:category=>@category)
    yield @latest_news
  end

  def kriminal_video_news
    @video_news=Cms::News.newest_multimedia(1,[:video],["category_id=? AND id NOT IN(?) AND is_blog=?", @category.id,@latest_news,false]).first
    yield @video_news if @video_news
  end

  def kriminal_photo_news
    @photo_news=Cms::News.newest_multimedia(1,[:photo],["category_id=? AND id NOT IN(?) AND is_blog=?", @category.id,(@latest_news || [])+[@video_news],false]).first
    yield @photo_news if @photo_news
  end

  def kriminal_main_tag_news
    if @category.default_tag.to_s.size>0
      ids=@latest_news+[@video_news,@photo_news]
      tag=Cms::Tag.find_by_name(@category.default_tag)
      @kriminal_main_tag_news=tag.news.find(:all,:conditions=>["category_id=? AND cms_news.id NOT IN(?) AND is_blog=?",@category.id,ids,false],:order=>"publication_date desc",:limit=>5)
      yield tag,@kriminal_main_tag_news
    end
  end

  def kriminal_newest_news
    ids=((@latest_news || [])).compact.collect{|n| n.is_a?(Cms::News) ? n.id : n}
    Cms::News.newest(17,{:conditions=>["category_id=? AND is_blog=? AND cms_news.id NOT IN (?)",@category.id,false,ids]}).each{|n| yield n}
  end
  
  def simple_rating(news)
    "<span>#{news.total_rating}</span>"
  end

  def kriminal_media_icons_for news,attributes={}
    photo_icon=news.media_photo ? image_tag("kriminal/kriminal-foto-ico.gif",{:alt=>""}.merge(attributes)) : ""
    video_icon=news.media_video ? image_tag("kriminal/kriminal-video-ico.gif", {:alt=>""}.merge(attributes)) : ""
    audio_icon=news.media_audio ? image_tag("kriminal/kriminal-lout-ico.gif", {:alt=>""}.merge(attributes)) : ""
    photo_icon + video_icon + audio_icon
  end
end
