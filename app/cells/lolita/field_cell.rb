class Lolita::FieldCell < Lolita::Cells
  before_filter :set_field
  
  def display
    render
  end

  def label
    render
  end

  def string
    render
  end

  def integer
    render :view=>"string"
  end

  def datetime
    render :view=>"string"
  end
  
  def text
    render
  end

  def disabled
    render
  end

  def array
    render :view=>"string"
  end
  private

  def set_field
    @field=@opts[:field]
  end
end