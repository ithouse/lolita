module Extensions::FileExtensions
  def first_pdf
    find(:first,:conditions=>"name_mime_type='application/pdf' || name_mime_type='attachment/octet-stream'")
  end
end
