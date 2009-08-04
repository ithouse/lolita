module ITHouse
  module Filters
    module AdvancedFilterHelper

      def set_object_name name
        @module=name.camelize.constantize if name
      end
      def advanced_filter_options options={}
        default_options={

        }
        default_options.merge(options)
      end
      def advanced_filter options={}
        render :partial=>"/cms/advanced_filter", :object=>options
      end

      def saved_filters(current_filter=0)
        options=[["-#{t(:"advanced filter.new filter")}-",0]]+@module.advanced_filter_for_options
        default=current_filter.to_i
        options_for_select options,default
      end

      def filter_columns(current_filter=0)
        options=@module.load_advanced_filter(current_filter).collect{|row|[row[:title].is_a?(Symbol) ? t(row[:title]) : row[:title],row[:name],{:disabled=>row[:visible]}]}
        default=nil
        cms_options_for_select options,default  #izmantoju CMS
      end

      def create_filter current_filter=0
        filter= @module.load_advanced_filter(current_filter)
        filter.each{|column|
          cols=[
            content_tag("td",filter_title(column),:class=>"first-column"),
            content_tag("td",filter_condition(column)),
            content_tag("td",filter_value(column)),
            content_tag("input","",:type=>"hidden",:value=>"#{column[:visible] ? 'true' : 'false'}",:name=>"advanced_filter[is_visible][#{column[:name]}]", :id=>"is_visible_#{column[:name]}")
          ].join("")
          yield content_tag("tr",cols,:id=>"tr_#{column[:name]}",:class=>"filter",:style=>"#{column[:visible] ? "" : 'display:none;'  }")
        }

      end

      def filter_title options={}
        %(<input type="checkbox" value="#{options[:name]}" name="advanced_filter[fields][]" id="cb_#{options[:name]}" #{options[:active] ? 'checked="checked"' : ''}/>
          <label for="cb_#{options[:name]}">#{options[:title].is_a?(Symbol) ? t(options[:title]) : options[:title]}</label>)
      end

      def filter_condition options={}
        case options[:type]
        when :scalar
          default=options[:condition] || (options[:conditions][0].is_a?(Array) ? options[:conditions][0][1] : options[:conditions][0])
          options[:conditions].collect!{|value| value<<{:style=>"font-size:14px;"}}
          %(<select style="vertical-align: top;" name="advanced_filter[conditions][#{options[:name]}]" id="conditions_#{options[:name]}" class="small">
            #{cms_options_for_select options[:conditions],default,false}
          </select>) #izmantoju CMS
        when :numeric
          content_tag("input","",
            :type=>"text",
            :class=>"select-small",
            :size=>options[:limit],
            :name=>"advanced_filter[conditions][#{options[:name]}]",
            :style=>"float:left;"
          )+"<span style='float:left'>&#37;</span> "
        when :datetime
          %(<input type="hidden" name="advanced_filter[conditions][#{options[:name]}]" id="conditions_#{options[:name]}" value="smaller_or_same"/>)
        end
      end

      def filter_value options={}
        case options[:type]
        when :scalar
          if options[:foreign]
            content_tag("div",
              content_tag("select",cms_options_for_select(options[:foreign_data] ? options[:foreign_data][:values] : [],options[:values].collect{|v| v.to_i}), #izmantoju CMS
                :class=>"medium",
                :id=>"values_#{options[:name]}",
                :name=>"advanced_filter[values][#{options[:name]}][]"
              )+
                content_tag("span",
                image_tag("/lolita/images/icons/expand.png",:alt=>"#{t(:"simple words.expand")}",:id=>"values_#{options[:name]}_expand",:onclick=>"AdvancedFilter.toggleSelect(this,'#values_#{options[:name]}')"),
                :style=>"margin-left:2px;vertical-align:top;"),
              :id=>"div_values_#{options[:name]}")
          else
            content_tag("div",
              content_tag("input","",
                :type=>"text",
                :size=>options[:native_type]==:integer || options[:native_type]==:float ? 10 : options[:limit],
                :name=>"advanced_filter[values][#{options[:name]}][]",
                :id=>"values_#{options[:name]}",
                :value=>options[:values] ? options[:values].first : "",
                :class=>"value"
              ),
              :id=>"div_values_#{options[:name]}")
          end
        when :datetime
          options[:values]=[] unless options[:values]
          content_tag("div",
            content_tag("select",cms_options_for_select([1,2,3,4,5,6,7,8,9,10,11,12],options[:values].first), #izmantoju CMS
              :class=>"small",
              :id=>"values_#{options[:name]}",
              :name=>"advanced_filter[values][#{options[:name]}][]"
            )+
              content_tag("select",cms_options_for_select([[t(:"time.than.days"),"day"],[t(:"time.than.weeks"),"week"],[t(:"time.than.months"),"month"],[t(:"time.than.years"),"year"]],options[:values].last), #izmantoju CMS
              :class=>"medium",
              :id=>"values_#{options[:name]}",
              :name=>"advanced_filter[values][#{options[:name]}][]"
            ),
            :id=>"div_values_#{options[:name]}")
        end
      end
    end

  end
end
