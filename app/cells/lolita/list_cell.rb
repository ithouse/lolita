class Lolita::ListCell < Lolita::Cells
  def display
    @list = @opts[:list]
    @page=@opts[:page]
    render
  end

  def header
    render
  end

  def header_cell
    render
  end

  def body
    render
  end

  def row
    @class_name=@opts[:index]%2==0 ? "even" : "odd"
    @record=@opts[:record]
    render
  end

  def body_cell
    render
  end

  def paginator
    @columns=@opts[:columns]
    render
  end
end
