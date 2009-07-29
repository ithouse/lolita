class WikiPage < ActiveRecord::Base
  validates_uniqueness_of :name
  CamelCase = Regexp.new('\\[\w+\\]')

  def links
    links=[]
    self.content.gsub(/#{WikiPage::CamelCase}/){|match|
      if block_given?
        yield match.gsub(/[\[\]]/,"")
      else
        links<<match.gsub(/[\[\]]/,"")
      end
    }
    unless block_given?
      links
    end
  end

  def self.full_page_tree
    pages=self.find(:all,:order=>:name)
    full_tree=[]
    pages.each{|page|
      full_tree<<{:name=>page.name,:level=>1}
      page.page_tree(page.links,[page],1) do |branch|
        full_tree<<branch if branch
      end
    }
    full_tree
  end

  def page_tree links,parents,level
    links.each{|link|
      current=WikiPage.find_by_name(link)
      unless parents.include?(current)
        branch={:name=>link,:level=>level+1}
        yield branch
        current.page_tree(current.links,parents+[current],level+1)
      end
      yield false
    }
  end
end
