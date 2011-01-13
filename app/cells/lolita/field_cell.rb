class Lolita::FieldCell < Lolita::Cells
  def display
    @field=@opts[:field]
    render
  end

  def label
    @field=@opts[:field]
    render
  end

  def string
    @field=@opts[:field]
    render
  end
end