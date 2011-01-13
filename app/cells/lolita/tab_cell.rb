class Lolita::TabCell < Lolita::Cells

  def display
    @tab=@opts[:tab]
    render
  end

  def default
    @tab=@opts[:tab]
    render
  end

  def content
    @tab=@opts[:tab]
    render :view=>:default
  end
  
end
