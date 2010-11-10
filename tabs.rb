module Lolita
  module Configuration
    class Tabs 
      include Enumerable

      attr_reader :tabs
      
      def initialize(&block)
        block_given? ? self.instance_eval(&block) : self.generate
      end

      def each
        @tabs.each{|tab|
          yield tab
        }
      end
 # tabs.add(:content).add(:image).add(news FileItemTab())
      def add(*args)
#        @tabs<<Lolita::LazyLoader(self,:@tab,Tabs,&block)
#        self
#        Lolita::Buffer.add(self,:add,*args) # @lolita_buffer=>{:add=>args}
      end
# tabs.each do |t|
#   if t.is_a?(ImageTab)
#
#   end
# end
# tabs[0] #=> #<Lolita::LazyLoader:0x2681460>
# tabs[0].type #=> <Lolita::Tab:blabla>
      def generate
        puts "Generate tabs..."
      end
    end
  end
end