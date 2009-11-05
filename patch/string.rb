# coding:utf-8
class ::String

  def translit options = {}
    cyr_to_trans = {'а'=>'a','б'=>'b','в'=>'v','г'=>'g','д'=>'d','е'=>'e','ё'=>'e','ж'=>'zh','з'=>'z','и'=>'i','й'=>'i','к'=>'k','л'=>'l','м'=>'m','н'=>'n','о'=>'o','п'=>'p','р'=>'r','с'=>'s','т'=>'t','у'=>'u','ф'=>'f','х'=>'h','ц'=>'c','ч'=>'ch','ш'=>'sh','щ'=>'sht','ъ'=>'u','ь'=>'y','ы'=>'y','э'=>'e','ю'=>'yu','я'=>'ya',
      'А'=>'a','Б'=>'b','В'=>'v','Г'=>'g','Д'=>'d','Е'=>'e','Ё'=>'e','Ж'=>'zh','З'=>'z','И'=>'i','Й'=>'i','К'=>'k','Л'=>'l','М'=>'m','Н'=>'n','О'=>'o','П'=>'p','Р'=>'r','С'=>'s','Т'=>'t','У'=>'u','Ф'=>'f','Х'=>'h','Ц'=>'c','Ч'=>'ch','Ш'=>'sh','Щ'=>'sht','Ъ'=>'u','Ь'=>'y','Ы'=>'y','Э'=>'e','Ю'=>'yu','Я'=>'ya'}
    lat_to_trans = {'ā'=>'aa','č'=>'ch','ē'=>'ee','ģ'=>'gj','ī'=>'ii','ķ'=>'kj','ļ'=>'lj','ņ'=>'nj','š'=>'sh','ū'=>'uu','ž'=>'zh',
      'Ā'=>'aa','Č'=>'ch','Ē'=>'ee','Ģ'=>'gj','Ī'=>'ii','Ķ'=>'kj','Ļ'=>'lj','Ņ'=>'nj','Š'=>'sh','Ū'=>'uu','Ž'=>'zh'}
 
    self.gsub(/./){|s| ((options[:only_lv])? nil : cyr_to_trans[$&]) || ((options[:only_ru])? nil : lat_to_trans[$&]) || $& }
  end

  def lv_to_ascii
    self.gsub(/./){|s| {
      'ā'=>'a','č'=>'c','ē'=>'e','ģ'=>'g','ī'=>'i','ķ'=>'k','ļ'=>'l','ņ'=>'n','š'=>'s','ū'=>'u','ž'=>'z',
      'Ā'=>'A','Č'=>'c','Ē'=>'E','Ģ'=>'G','Ī'=>'I','Ķ'=>'K','Ļ'=>'L','Ņ'=>'N','Š'=>'S','Ū'=>'U','Ž'=>'Z'
    }[$&] || $& }
  end

  def to_url options = {}
    # slugify => true
    # Ne vienmēr vajag translītām ar slugify LV burti tiek konvertēti 1:1
    (options[:slugify] ? self.translit(:only_ru=>true).lv_to_ascii : self.translit).gsub(/[\s—–]/,"-").gsub(/[^a-zA-Z0-9-]/,'-').gsub(/-{2,}/,"-").gsub(/^\W+|\W+$/,"")
  end
  #atpakaļ gājienā visas - pārvērš par atstarpēm, kaut vai tā nav bijis
  
  # Parametri
  #   :jautajums - [kas, kā, ko, kam, kur] kāds no šiem
  #   :opcijas
  #     :locijums - tagadējais locījums, ja tas ir kāds cits neis kas?
  #     :dekl - deklinācija, ja ir locījumā vai arī nominātīvā ja ir 6
  #     :daudzsk - vai ir vajadzīgs daudzskaitlī, TODO nevar būt daudzskaitī sākumā
  def locit(jautajums,options={})
    locijums = options[:locijums] ? options[:locijums].to_sym : "kas?".to_sym
    jautajums=jautajums.to_sym

    spec_words={
      2=>["mēness", "akmens", "asmens", "rudens", "ūdens", "zibens", "suns", "sāls"],
      6=>["ļaudis"],
    }
    galotnes={
      1=>{"kas?".to_sym=>["s","š"],"kā?".to_sym=>"a","kam?".to_sym=>"am","ko?".to_sym=>"u","kur?".to_sym=>"ā"},
      2=>{"kas?".to_sym=>"is","kā?".to_sym=>"a","kam?".to_sym=>"im","ko?".to_sym=>"i","kur?".to_sym=>"ī"},
      3=>{"kas?".to_sym=>"us","kā?".to_sym=>"us","kam?".to_sym=>"um","ko?".to_sym=>"u","kur?".to_sym=>"ū"},
      4=>{"kas?".to_sym=>"a","kā?".to_sym=>"as","kam?".to_sym=>"ai","ko?".to_sym=>"u","kur?".to_sym=>"ā"},
      5=>{"kas?".to_sym=>"e","kā?".to_sym=>"es","kam?".to_sym=>"ei","ko?".to_sym=>"i","kur?".to_sym=>"ē"},
      6=>{"kas?".to_sym=>"s","kā?".to_sym=>"s","kam?".to_sym=>"ij","ko?".to_sym=>"i","kur?".to_sym=>"ī"},
    }
    dekl=options[:dekl]
    if !dekl && locijums=="kas?".to_sym
      dekl=if self.match(/is$/) || spec_words[2].include?(self)
        2
      elsif self.match(/us$/)
        3
      elsif self.match(/s$/) || self.match(/š$/)
        1
      elsif self.match(/a$/)
        4
      elsif self.match(/e$/)
        5
      end
    end
    if dekl
      if galotnes[dekl][locijums].is_a?(Array)
        sakuma_galotne=galotnes[dekl][locijums].find{|galotne| self.match(/#{galotne}$/)}
      end
      if dekl==2
        is_spec_word=nil
        spec_words.each{|word|
          galotnes[2].each{|q,g|
            is_spec_word=self.gsub(/#{g}$/,galotnes[2]["kas?".to_sym])==word
          }
        }
        sakuma_galotne=is_spec_word ? "s" : sakuma_galotne
      end
      if galotnes[dekl][jautajums].is_a?(Array)
        beigu_galotne=galotnes[dekl][jautajums].first #TODO nevar notiekt, ja ir pirmā deklinācija locījumā un vajag nominātīvu, tad kāda galotne būs
      end
      return self.gsub(/#{sakuma_galotne}$/,"#{beigu_galotne}")
    else
      self
    end

  end
  #ja vajag sesto deklināciju tad jānorāda "nakts".daudzskaitlis("s")
  #TODO nevar atpazīt ģenetīveņus
  #TODO nevar atpazīt vienskaitliniekus
  #TODO nevar atpazīt daudzskaitliniekus
  #TODO nevar atpazīt ka vārds jau ir daudzskaitlī
  def daudzskaitlis(dzimte=nil, locijums=:kas?)
    dzimte=dzimte && ["s","siev","siev.","sieviešu"].include?(dzimte) ? "sieviešu" : "vīriešu"
    spec_words={
      2=>["mēness", "akmens", "asmens", "rudens", "ūdens", "zibens", "suns", "sāls"],
      6=>["ļaudis"],
    }
    if self.match(/is$/) || spec_words[2].include?(self.downcase) # 2. deklinācija
      mijas={"b"=>"bj","m"=>"mj", "p"=>"pj","v"=>"vj","t"=>"š","d"=>"ž","c"=>"č","dz"=>"dž",
        "s"=>"š","z"=>"ž","n"=>"ņ","l"=>"ļ","sn"=>"šņ","zn"=>"žņ","sl"=>"šļ","zl"=>"žļ","ln"=>"ļņ",
      }
      excluded_izsk=["astis","jis","ķis","ģis","ris","skatis"]
      normalized_word=self.downcase
      sakne=spec_words[2].include?(normalized_word) ? normalized_word.gsub(/s$/,"") : normalized_word.gsub(/is$/,"")
      excluded=excluded_izsk.any?{|izsk| normalized_word.match(/#{izsk}$/)}
      #mija nav personu vārdos ar divām zilbēm, kas beidzas ar -dis un -tis, kā
      #arī uzvārdos kas biedzas ar -skis, -ckis
      excluded=normalized_word.match(/^[A-Z]/) && (((normalized_word.match(/dis$/) || normalized_word.match(/tis$/)) && normalized_word.match(/[aeiou]/).size==2) || (normalized_word.match(/skis$/) || normalized_word.match(/ckis$/))) unless excluded
      excluded=["tētis","viesis"].include?(normalized_word) unless excluded
      unless excluded
        mijas.each{|now,mija|
          if sakne.match(/#{now}$/)
            sakne.gsub!(/#{now}$/,mija)
            break
          end
        }
      end
      "#{sakne}i"
    elsif self.match(/us$/)
      self.gsub(/us$/,"i")
    elsif self.match(/s$/) && dzimte=="vīriešu" && !spec_words[6].include?(self.downcase)
      self.gsub(/s$/,"i")
    elsif self.match(/š$/)
      self.gsub(/š$/,"i")
    elsif self.match(/a$/)
      self.gsub(/a$/,"as")
    elsif self.match(/e$/)
      self.gsub(/e$/,"es")
    elsif (self.match(/s$/) && dzimte=="sieviešu") || spec_words[6].include?(self.downcase)
      spec_words[6].include?(self.downcase) ? self : self.gsub(/s$/,"is")
    else
      self
    end
  end
  #  def capitalize
  #    letters=self.split(//)
  #    if idx=['a','ā','b','c','č','d','e','ē','f','g','ģ','h','i','ī','j','k','ķ','l','ļ','m','n','ņ','o','p','r','s','š','t','u','ū','v','z','ž','x','y','q','w'].index(letters[0])
  #      letters[0]=['A','Ā','B','C','Č','D','E','Ē','F','G','Ģ','H','I','Ī','J','K','Ķ','L','Ļ','M','N','Ņ','O','P','R','S','Š','T','U','Ū','V','Z','Ž','X','Y','Q','W'][idx]
  #    end
  #    letters.join
  #  end
  def to_array
    array=[]
    self.gsub!(/\[/,"")
    self.gsub!(/\]/,"")
    values=self.split(/\,/)

    values.each{|value|
      array<<value
    }
    array
  end

  # strips tags and add's \n in place of br,p,h1,h2... and save's links
  def to_text
    result = self.gsub(/>(\s)+</){|m| ">#{$2}<"}
    result = result.gsub(/<\/[^>]*(p|h1|h2|h3)>/,"\n\n")
    result = result.gsub(/<br\s?\/?>/,"\n")
    result = result.gsub(/<a[^>]*href=\"(.*)\">([^<]*)<\/[^>]*>/){|m|
      m.match(/href=\"(.*)\">([^<]*)</)
      "#{$2} #{$1}"
    }
    result.gsub(/<\/?[^>]*>/, "")
  end
end
