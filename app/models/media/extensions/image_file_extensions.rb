module Media::Extensions::ImageFileExtensions
  # Round image corners.
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

  # Create an opacit grayscale version of the image on a solid background.
  #:image_file_grayout=>{:versions=>[:some_version[,...]],
  #    :some_version=>float opacity || :some_version=>{:background=>rmagick color,:opacity=>float opacity} }
  # default opacity is 0.5 (50%), background color "white"
  def image_file_grayout picture,options={}
    (options && options[:versions] || []).each{|version|
      picture.send(version).process! do |img|
        options[version]||={}
        options[version][:opacity]=options[version] if options[version].is_a?(Numeric)
        options[version][:opacity]=0.5 unless options[version][:opacity]
        options[version][:background]="white" unless options[version][:background]
        width=img.columns
        height=img.rows
        #lay original image over background to avoid transparent areas going inverted
        opacity_mask = Magick::Image.new(width,height)
        opacity_mask.background_color=options[version][:background]
        img.composite!(opacity_mask,Magick::CenterGravity, Magick::DstAtopCompositeOp)
        img.opacity=Magick::QuantumRange*options[version][:opacity]
        #lay over background again and grayscale
        img.composite!(opacity_mask,Magick::CenterGravity, Magick::DstAtopCompositeOp)
        img.image_type = Magick::GrayscaleType
        img
      end
    }
  end

end