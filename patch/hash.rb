class ::Hash
  # converts all keys to symbols, but RECURSIVE
  def symbolize_keys!
    each do |k,v|
      sym = k.respond_to?(:to_sym) ? k.to_sym : k
      self[sym] = Hash === v ? v.symbolize_keys! : v
      delete(k) unless k == sym
    end
    self
  end
  # converts Hash and HashWithIndifferentAccess to readable HTML like
  # >> {:a => 1, :b => {:c => 55}}.to_html
  # => "<ul><li>a => 1</li><li>b => <ul><li>c => 55</li></ul></li></ul>"
  def to_html
    "<ul>#{self.collect{|k,v| "<li>#{k} => #{([Hash,HashWithIndifferentAccess].include?(v.class))? v.to_html : v}</li>"}}</ul>"
  end
end
