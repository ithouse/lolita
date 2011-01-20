class Object
  # Works similar as <code>attr_accessor</code> only reader method is changed
  # to allow to set value (used for Lolita blocks in different classes).
  # ====Example
  #     class Klass
  #       lolita_accessor :my_method
  #     end
  #     k=Klass.new
  #     k.my_method("it's me")
  #     puts k.my_method #=> it's me
  def lolita_accessor *methods
    if [Class,Module].include?(self.class)
      methods.each do |method|
        class_eval <<-ACCESSORS,__FILE__,__LINE__+1
        def #{method}(value=nil)
          @#{method}=value if value
          @#{method}
        end

        def #{method}=(value)
          @#{method}=value
        end
        ACCESSORS
      end
    end
  end
end