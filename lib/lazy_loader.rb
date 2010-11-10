module Lolita
  class LazyLoader

    #attr_reader :lazy_class,:eval_block,:class_instance
    
    def self.lazy_load(instance_name,var_name,lazy_class,*args,&block)
      temp_var=instance_name.instance_variable_get(var_name)
      unless temp_var
        temp_var=instance_name.instance_variable_set(var_name,self.new(lazy_class,*args,&block))
      end
      if temp_var.to_s=~/Lolita::LazyLoader/ && temp_var.class_instance
        instance_name.instance_variable_set(var_name,temp_var.class_instance)
      else
        temp_var
      end
    end
    
    def initialize(lazy_class,*args,&block)
      @args=args
      @lazy_class=lazy_class
      @eval_block=block
    end

    def class_instance
      @class_instance
    end
    
    def method_missing(method_name,*args,&block)
      unless @class_instance
        puts @lazy_class.to_s
        arity=@lazy_class.instance_method(:initialize).arity
        puts "-#{arity}"
        if arity==-1 # when expectign *args
          @class_instance=@lazy_class.new(*@args,&@eval_block)
        elsif arity.abs>0 # when expecting specific number of arguments without any *args
          @class_instance=@lazy_class.new(*@args.slice(0..arity.abs-1),&@eval_block)
        else
          @class_instance=@lazy_class.new(&@eval_block)
        end
      end
      @class_instance.__send__(method_name,*args,&block)
    end
    
    instance_methods.each { |method|
      next if ["hash","respond_to?","__id__","__send__","to_s","object_id","method_missing","class_instance","initialize"].include?(method.to_s)
      eval("undef :#{method}")
    }
  end
end
