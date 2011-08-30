class Lolita::InfoController < ApplicationController
  @@properties = []

  def index
    if Lolita.mappings.any?
      return redirect_to(lolita_resources_path(Lolita.mappings.values.first))
    end
    render :layout => false
  end

  def properties
    if request.local?
      render :inline => to_html
    else
      render :text => '<p>For security purposes, this information is only available to local requests.</p>', :status => :forbidden
    end
  end

  private

  def self.property(name, value = nil)
    value ||= yield
    @@properties << [name, value] if value
    rescue Exception
  end

  def to_html
    (table = '<table>').tap do
      @@properties.each do |(name, value)|
        table << %(<tr><td class="name">#{CGI.escapeHTML(name.to_s)}</td>)
        formatted_value = if value.kind_of?(Array)
              "<ul>" + value.map { |v| "<li>#{CGI.escapeHTML(v.to_s)}</li>" }.join + "</ul>"
            else
              CGI.escapeHTML(value.to_s)
            end
        table << %(<td class="value">#{formatted_value}</td></tr>)
      end
      table << '</table>'
    end
  end
    
  property 'Lolita version', "#{LOLITA_VERSION}"

end
