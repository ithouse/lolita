#module DuppyUtils
class ::Array
  def uniq_joins
    join_tables=[]
    self.collect{|join|
      if join
        join_table_name=""
        join.match(/join \W\w+\W/i){|s| join_table_name=s.gsub(/join /i,"")}
        unless join_tables.include?(join_table_name)
          join_tables<<join_table_name
          join
        end
      end
    }.compact
  end
end
#end
