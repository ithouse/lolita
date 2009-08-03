pdf.image "prawn/smsbuzz.lv-logo.png", :width=>150

pdf.font_families.update(
   "Verdana" => { :bold        => "prawn/Verdana_Bold.ttf",
                  :normal      => "prawn/Verdana.ttf" })

pdf.font("Verdana")

pdf.stroke_color = "999999"
pdf.line_width = 0.1
now = @data[:date]
pdf.move_down(25)

pdf.text "RĒĶINS nr. #{@data[:id]}", :align=>:center, :font_size=>14, :style=>:bold
# :style=>:bold

pdf.font_size = 9

pdf.bounding_box([100,600], :width =>200) do
    pdf.text "#{now.strftime("%Y.gada %d.")} #{t(:"months.#{now.strftime("%B").downcase}").capitalize}", :style=>:bold
end

pdf.bounding_box([0,590], :width=>520) do
    pdf.move_down(15)
    pdf.text "Piegādātājs", :at=>[0,0]
    pdf.text "#{@data[:provider]}", :at=>[100,0], :style=>:bold
    pdf.text "Reģ. Nr.", :at=>[300,0]
    pdf.text "#{@data[:provider_reg_nr]}", :at=>[365,0]

    pdf.text "Juridiskā adrese", :at=>[0, -15]
    pdf.text "#{@data[:provider_address]}", :at=>[100, -15]
    pdf.text "PVN Nr.", :at=>[300,-15]
    pdf.text "#{@data[:provider_vat_nr]}", :at=>[365,-15]

    pdf.text "Norēķinu rekvizīti", :at=>[0,-30]
    pdf.text "#{@data[:provider_bank]}", :at=>[100, -30]
    pdf.text "Konts", :at=>[300,-30]
    pdf.text "#{@data[:provider_bank_account]}", :at=>[365,-32]
    
    pdf.stroke do
        pdf.line pdf.bounds.top_left, pdf.bounds.top_right
    end
end

pdf.bounding_box([0,540], :width=>520) do
    pdf.move_down(14)
    pdf.text "Saņēmējs", :at=>[0,0]
    pdf.text "#{@data[:receiver]}", :at=>[100,0], :style=>:bold
    if(@data[:receiver_reg_nr])
      pdf.text "Reģ. Nr.", :at=>[300,0]
      pdf.text "#{@data[:receiver_reg_nr]}", :at=>[365,0]
    else
      pdf.text "Pers. kods", :at=>[300,0]
      pdf.text "#{@data[:receiver_person_code]}", :at=>[365,0]
    end
    pdf.text (((@data[:receiver_vat_nr])? "Juridiskā adrese" : "Adrese"), :at=>[0, -15])
    pdf.text "#{@data[:receiver_address]}", :at=>[100, -15]
    pdf.text "PVN Nr.", :at=>[300,-15] if @data[:receiver_vat_nr]
    pdf.text "#{@data[:receiver_vat_nr]}", :at=>[365,-15] if @data[:receiver_vat_nr]

    #pdf.text "Norēķinu rekvizīti", :at=>[0,-30]
    #pdf.text "#{@data[:receiver_bank]}", :at=>[100, -30]
    #pdf.text "Konts", :at=>[300,-30]
    #pdf.text "#{@data[:receiver_bank_account]}", :at=>[365,-30]

    pdf.stroke do
        pdf.line pdf.bounds.top_left, pdf.bounds.top_right
    end
end

pdf.bounding_box([0,505], :width=>520) do
    pdf.text "Apmaksas termiņš", :at=>[0,-15]
    pdf.text "#{now.strftime("%Y.gada %d.")} #{t(:"months.#{now.strftime("%B").downcase}").capitalize}", :at=>[100,-15], :style=>:bold
    #pdf.text "Līguma Nr.", :at=>[300,-30]
    #pdf.text "#{@data[:contract_nr]}", :at=>[400,-30]

    pdf.text "Apmaksas veids", :at=>[0, -30]
    pdf.text "#{@data[:payment_method]}", :at=>[100, -30]

    pdf.stroke do
        pdf.line pdf.bounds.top_left, pdf.bounds.top_right
    end
end
pdf.bounding_box([0,460], :width=>520) do
    headers = ["Nosaukums", "Skaits", "Mērv.", "Cena", "Summa"]
    body = @data[:table_data]
    pdf.table body, :headers => headers,
        :align_headers=>:center,
        :align=>{0=>:left, 1=>:center, 2=>:center, 3=>:right, 4=>:right},
        :column_widths=>{0=>300, 1=>60, 2=>50, 3=>50, 4=>60},
        :border_style=>:grid,
        :vertical_padding=>2,
        :font_size=>9,
        :border_width=>0.1,
        :border_color=>"999999"

currency_amount = 0.0
body.each do |array|
  currency_amount += array.last.gsub(",",".").to_f
end
vat = (@data[:sum_with_vat])? @data[:sum_with_vat]-(@data[:sum_with_vat]/(1 + @pvn_percent)) : currency_amount * @pvn_percent
sum = (@data[:sum_with_vat])? @data[:sum_with_vat] : currency_amount + vat
pdf.bounding_box([300,-100], :width=>100) do
    pdf.text "SUMMA BEZ PVN", :align=>:right, :style=>:bold, :at=>[0,45]
    pdf.text "#{number_to_currency(currency_amount, :unit=>"Ls", :format=>"%n %u", :separator => ",", :delimiter => "")}", :align=>:left, :at=>[150,45]

    pdf.text "PVN #{100 * @pvn_percent}%", :align=>:right, :style=>:bold, :at=>[0,30]
    pdf.text "#{number_to_currency(vat, :unit=>"Ls", :format=>"%n %u", :separator=>",")}", :align=>:left, :at=>[150,30]

if @data[:discount_rate] != 0 then

    pdf.text "PIEMĒROTĀ ATLAIDE", :align=>:right, :style=>:bold, :at=>[0,15]
    pdf.text "#{@data[:discount_rate]} %", :at=>[150,15]

    discount_rate = @data[:discount_rate]
    sum = sum - (sum*discount_rate/100)

    pdf.text "SUMMA LVL", :align=>:right, :style=>:bold, :at=>[0,0]
    pdf.text "#{number_to_currency(sum, :unit=>"Ls", :format=>"%n %u", :separator => ",", :delimiter => "")}", :align=>:left, :at=>[150,0]

else

    pdf.text "SUMMA LVL", :align=>:right, :style=>:bold, :at=>[0,15]
    pdf.text "#{number_to_currency(sum, :unit=>"Ls", :format=>"%n %u", :separator => ",", :delimiter => "")}", :align=>:left, :at=>[150,15]

end
end

lats=sum.floor
spelled_lats=spell_number(lats, "m")
santims= ((sum-lats)*100).round
spelled_santims=spell_number(santims, "m")

pdf.bounding_box([0,-100], :width=>200) do
    pdf.text "Summa vārdiem", :at=>[0,30]
    pdf.text "#{spelled_lats} #{spelled_lats.last(5)=="viens" ? "lats" : "lati"} un #{spelled_santims} #{spelled_santims.last(5)=="viens" ? "santīms" : "santīmi"}", :at=>[100,30], :style=>:bold

    pdf.text "Papildus noteikumi", :at=>[0,15]
    pdf.text "#{@data[:additional_info]}", :at=>[100,15]

end

end

pdf.font_size = 8

pdf.text "ŠIS RĒĶINS SAGATAVOTS ELEKTRONISKI UN IR DERĪGS BEZ PARAKSTA UN ZĪMOGA" , :at=>[0,0], :font_size=>10