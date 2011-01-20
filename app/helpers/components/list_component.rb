module Components::ListComponent
  def row_ll
    @class_name=@opts[:index]%2==0 ? "even" : "odd"
  end
end
