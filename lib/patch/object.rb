class ::Object
  def to_b
    if self.is_a?(NilClass)
      return false
    end
    if self.is_a?(Numeric)
      return self!=0
    end
    if self.is_a?(Symbol)
      return self!=:false
    end
    if self.is_a?(String)
      return (!self.nil? && self.size>0)?(self.match(/(true|t|yes|y|1)$/i) != nil):false
    end
    if self.is_a?(Array) || self.is_a?(Hash)
      return self.size>0
    end
  end
end