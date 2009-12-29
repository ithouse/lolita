# coding:utf-8
module Extensions::NumberSpellerHelper # :nodoc

  
  def num_level_prefix
    ["nulle","vien","div","trīs","četr","piec","seš","septiņ","astoņ","deviņ"]
  end
   def number_to_native_name_single(num,sex='m')
    word=num_level_prefix[num] if num==3
    if sex=='f'
      word=num_level_prefix[num]+'a'  if num==1
      word=num_level_prefix[num]+'as' if num!=3 && num!=1
    else
      word=num_level_prefix[num]+'s' if num==1
      word=num_level_prefix[num]+'i' if num!=3 && num!=1
    end
    word
  end
  def number_to_native_name_simple(num,sex='m')
    case num
      when 0
        ""
      when 1..9
        number_to_native_name_single(num,sex)
      when 11..19
        word=num_level_prefix[num/10]+'padsmit'
      else
        dec=(num/10).floor
        single=num%10
        if dec==1
          word="desmit"
        else
          word=num_level_prefix[dec]+"desmit"
          unless single==0
            word+=" "+number_to_native_name_single(single,sex)
          end
          word
        end
    end
  end
  def number_to_native_hundreds(num,sex='m',karta=0)
    word=""
    if num>99 && num<1000
      word=number_to_native_name_single((num/100).floor,'m')
      word+="#{num/100<2 ? ' simts' : ' simti'} "
      num=num%100
    end
    word+=number_to_native_name_simple(num,(karta>0 ? 'm': sex ))
  end
  
  def spell_number(number,sex)
    if number>0
      num_level_names=["tūkstotis","miljons","miljards","triljons","kvadriljons",]
      num_level_plural_names=["tūkstoši","miljoni","miljardi","triljoni","kvadriljoni"]
      big_num=number
      karta=(Math.log10(number)/3).floor
      result=""
      start_karta=karta
      while karta>=0
        if karta<1
          result+=number_to_native_hundreds(big_num,sex)
        else
          divider=(1000**karta)
          num=(big_num/divider)
          num=0 if num==divider
          word=number_to_native_hundreds(num,sex,karta)
          if (karta==start_karta ) || (word!="" && karta!=start_karta)
            word+=" "+(num%10>0 ? num_level_plural_names[karta-1] : num_level_names[karta-1])
          end
          result+=word+" "
          big_num=(big_num-divider*num).floor
        end
        karta-=1
      end
      result
    else
      number_to_native_name_simple(0)
    end
  end
  alias_method :number_to_text , :spell_number
end
