class HumanControl < ActiveRecord::Base
 
  before_save :encrypt
  
  def self.check human_controller={}
    human_controller={} unless human_controller.is_a?(Hash)
    hc=HumanControl.find_by_picture_id(human_controller[:picture_id])
    if hc && hc.crypt(human_controller[:answer])==hc.text
      response=true
    else
      response=false
    end
    if hc
      require 'ftools'
      begin
        File.delete(RAILS_ROOT+'/public/images/'+hc.picture)
        temp_id=hc.id
        hc.destroy
        HumanControl.delete(temp_id)
      rescue
        #raise "Kļūda(3) Nevar izdzēst attēlu."
      end
    end
    response
  end
  def self.delete_old_images
    olds=HumanControl.find(:all,:conditions=>["created_at<?",Time.now()-180])
    require 'ftools'
    olds.each{|old|
      begin
        File.delete(RAILS_ROOT+'/public/images/'+old.picture)
        temp_id=old.id
        old.destroy
        HumanControl.delete(temp_id)
      rescue
        # raise "Kļūda(3) Nevar izdzēst attēlu."
      end
    }
    HumanControl.delete(olds) unless olds.empty?
  end
  def self.image
    delete_old_images
    require 'RMagick'
    background = Magick::ImageList.new(RAILS_ROOT+'/public/images/cms/human_control_small_background.png')
    img = Magick::ImageList.new
    img_width=150
    img_height=75
    img.new_image(img_width, img_height, Magick::TextureFill.new(background))
    # We set some text properties
    text = Magick::Draw.new
    point_size=img_height/1.7
    text.font_family = 'arial'
    text.pointsize = point_size/1.5
    text.gravity = Magick::CenterGravity
    final_text=""
    1.upto(4) do|idx|
      #if idx%2==0
        arr="1,2,3,4,5,6,7,8,9".split(",")
     # elsif idx%3==0
     #   arr="B,C,D,F,G,H,J,K,L,M,N,P,R,S,T,V,Z,X,Y,W,Q".split(",")
     # else
     #   arr=["A","E","I","U","O"]
     # end
      c=arr[rand(arr.size)]
#      case rand(3)
#      when 0
#        c=(rand(10)+48).chr
#      when 1,2
#        c=(rand(26)+65).chr
#      end
      y=img_height#rand(img_height/10*3)+img_height/10*7
      rotation=(rand(2)==1 ? 1 : -1)#*rand(img_height/10*7)
      x=(point_size+3)*(idx)
      color='#004A80' #Magick::Pixel.new(200,200,200) # !!! vai linux vai arī jaunajiem imagemagick nepatīk krāsas padošanas Magick::Pixel formā
      flipflop = Magick::AffineMatrix.new(1,  rotation*Math::PI/(15),  rotation*Math::PI/(15), 2,0, 0)

# Ēnas ņemam nost jo tās var tikai palīdzēt noteikt burtu kontūras
#      text.annotate(background, x,y,2,2, c) {
#        self.fill = 'gray83'
#        self.affine=flipflop
#      }
#      text.annotate(background, x,y,-1.5,-1.5, c) {
#        self.fill = 'gray40'
#        self.affine=flipflop
#      }
      text.annotate(background, x,y,0,0, c) {
        self.fill = color
        self.affine=flipflop
      }
      final_text+=c
    end
    picture_id=rand(1000000000)
    file_root=RAILS_ROOT+"/public/images/"
    file_name="human_control/human_control_#{picture_id}.gif"
    h_control=HumanControl.new(:text=>final_text,:picture=>file_name,:picture_id=>picture_id)
    if h_control.save!
      background.write(file_root+file_name)
      h_control
    else
      nil
    end
  end
  def crypt text
    Digest::SHA1.hexdigest("--#{salt}--#{text}--")
  end
  
  protected
  
  def encrypt
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{get_word(10)}--")
    self.text = crypt(self.text)
  end
 
  def get_word size
    word=""
    1.upto(size) do
      case rand(3)
      when 0
        c=(rand(10)+48).chr
      when 1
        c=(rand(26)+65).chr
      when 2
        c=(rand(26)+97).chr
      end
      word+=c
    end
    word
  end
end
