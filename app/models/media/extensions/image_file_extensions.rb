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
        image.modulate(*options[:options] || 1)
      end
    end
  end
  #Change brightness, saturation, hue of image
  #:image_file_modulate=>{:versions=>[:some_version[,...]],
  #    :some_version=>{ :brightness=>float[,:saturation=>float][,:hue=>float] } }
  def image_file_modulate picture,options={}
    (options && options[:versions] || []).each{|version|
      picture.send(version).process! do |image|
        bright_sat_hue=options[version]||{}
        image.modulate(
          bright_sat_hue[:brightness]||1,
          bright_sat_hue[:saturation]||1,
          bright_sat_hue[:hue]||1
        )
      end
    }
  end
  # Gamma-correct an image.
  #:image_file_gamma=>{:versions=>[:some_version[,...]],
  #    :some_version=>float gamma }
  # Values typically range from 0.8 (darker) to 2.3 (very light).
  def image_file_gamma picture,options={}
    (options && options[:versions] || []).each{|version|
      picture.send(version).process! do |image|
        image.gamma_channel( options[version] || 1 )
      end
    }
  end
end