module Extensions::Temp
  module ClassMethods
    def add_dot_remover(attrs=[])
        attrs.each{|attr| self[attr].extend AttrMethods}
    end
  end
  def self.included(base)
    base.extend(ClassMethods)
  end
  module AttrMethods
    def remove_dots
      a=1
      b=2
    end    
  end
end
