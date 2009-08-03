class WikiPageController < ApplicationController
  allow :all=>[:open,:index,:list]
  layout 'wiki_page/default'
 
  
  def index
    redirect_to :action=>:open, :id=>params[:id]
  end
  
  def open
    page_name=params[:id] || "Sākums"
    @page = WikiPage.find_by_name(page_name)
    @page = WikiPage.create( :name => page_name, :content=>'') unless @page
    @page.content.gsub!(/#{WikiPage::CamelCase}/){|match|
      name=match.gsub(/[\[\]]/,"")
      %(<a href="/wiki_page/open/#{name}">#{name}</a>)
    }
    render :template=>"wiki_page/main"
  end

  def edit
    @page_action = "Editing" 
    @page = WikiPage.find_by_name( params[:id] )
    render :template=>"wiki_page/main"
  end
  
  def save
    @page = WikiPage.find_by_name( params[:id])
    @page.content = params[:wiki_page][:content]
    if @page.save
      flash[:notice] = "Lapa veiksmīgi saglabāta" 
    else
      flash[:notice] = "Neizdevās saglabāt lapu" 
    end
    redirect_to( :action => "open", :id => @page.name )
    
  end

  def list
    @pages = WikiPage.full_page_tree
    render :template=>"wiki_page/main"
  end
  
end
