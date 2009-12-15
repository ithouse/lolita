module Media::Extensions::ImageFileExtensions
  # round image corners
  def image_file_round_corners picture,options={}
    (options && options[:versions] || []).each{|version|
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
  #converts the image to grayscale
  # can pass :options - it will pass them to modulate function as (brightness=1.0, saturation=1.0, hue=1.0)
  def image_file_grayscale picture,options={}
    (options && options[:versions] || []).each do |version|
      picture.send(version).process! do |image|
        image.image_type = Magick::GrayscaleType
        image = image.modulate(*options[:options]) if options[:options]
      end
    end
  end
end
