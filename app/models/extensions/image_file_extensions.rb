#Deprecated!
module Extensions::ImageFileExtensions # :nodoc:
  def main_image
    find(:first,:conditions=>["main_image=?",true])
  end
  def main_or_first
    if pic=main_image
      pic
    else
      find(:first,:order=>"position asc")
    end
  end
  def without_main
    find(:all,:conditions=>["main_image=?",false])
  end
  def search_by_name(str,whole_word=false)
    if whole_word
      find(:all,:conditions=>["picture LIKE ?",str])
    else
      find(:all,:conditions=>["picture LIKE ","%#{str}%"])
    end
  end
end
