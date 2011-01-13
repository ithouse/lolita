class Lolita::FieldSetCell < Lolita::Cells
  def display
    @fields=@opts[:fields]
    @field_set=@opts[:field_set]
    render
  end
end