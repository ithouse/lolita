module Lolita
  class LazyLoader

    #attr_reader :lazy_class,:eval_block,:class_instance

    def self.lazy_load(instance_name,var_name,lazy_class,*args,&block)
      temp_var = instance_name.instance_variable_get(var_name)
      is_loader = temp_var.to_s =~ /Lolita::LazyLoader/
      if !temp_var || ((args && args.any? && is_loader && temp_var.__is_args_diff__(args)) || block_given?)
        temp_var = instance_name.instance_variable_set(var_name,self.new(lazy_class,*args,&block))
      end
      if temp_var.to_s =~ /Lolita::LazyLoader/
        temp_var = instance_name.instance_variable_set(var_name,temp_var.class_instance)
      end
      temp_var
    end

    def __is_args_diff__(args)
      @args != args
    end

    def initialize(lazy_class,*args,&block)
      @args = args || []
      @lazy_class=lazy_class
      @eval_block=block
    end

    def class_instance
      @class_instance || self
    end

    def method_missing(method_name,*args,&block)
      unless @class_instance
        @args = @args.empty? && [nil] || @args
        arity=@lazy_class.instance_method(:initialize).arity
        if arity==-1 # when expectign *args
          @class_instance=@lazy_class.new(*@args,&@eval_block)
        elsif arity.abs>0 # when expecting specific number of arguments without any *args
          @class_instance=@lazy_class.new(*@args.slice(0..arity.abs-1),&@eval_block)
        else
          @class_instance=@lazy_class.new(&@eval_block)
        end
      end
      if @class_instance.respond_to?(:after_initialize,true)
        @class_instance.__send__(:after_initialize)
      end
      @class_instance.__send__(method_name,*args,&block)
    end

    instance_methods.each { |method|
      next if ["!","__is_args_diff__","hash","respond_to?","__id__","__send__","to_s","object_id","method_missing","class_instance","initialize", "__args__"].include?(method.to_s)
      eval("undef :#{method}")
    }
  end
end