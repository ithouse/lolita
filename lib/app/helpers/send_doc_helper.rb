module SendDocHelper
  protected
  def cache_hack
    if request.env['HTTP_USER_AGENT'] =~ /msie/i
      headers['Pragma'] = ''
      headers['Cache-Control'] = ''
    else
      headers['Pragma'] = 'no-cache'
      headers['Cache-Control'] = 'no-cache, must-revalidate'
    end
  end

  def send_doc(xml, xml_start_path, report, filename, output_type = 'pdf')
    language='lv'
    case output_type
    when 'xls'
      extension = 'xls'
      mime_type = 'application/vnd.ms-excel'
      jasper_type = 'xls'
    else # pdf
      extension = 'pdf'
      mime_type = 'application/pdf'
      jasper_type = 'pdf'
    end

    cache_hack
    send_data Document.generate_report(xml, report, jasper_type, xml_start_path,language),
        :filename => "#{filename}.#{extension}", :type => mime_type, :disposition => 'inline'
  end
end
