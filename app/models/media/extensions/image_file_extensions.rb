module Media::Extensions::ImageFileExtensions
  # round image corners
  def image_file_round_corners picture,options={}
    (options[:versions] || []).each{|version|
      picture.send(version).process! do |image|
        width = image.columns
        height = image.rows
        masq = Magick::Image.new(width, height)
        d = Magick::Draw.new
        d.roundrectangle(0, 0, width - 1, height - 1, 3, 3)
        d.draw(masq)
        image.composite(masq, 0, 0, Magick::LightenCompositeOp)
      end
    }
  end
end