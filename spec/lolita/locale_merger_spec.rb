require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def fetch_keys h
  keys = []
  h.each do |k,v|
    if v.is_a? Hash
      keys += fetch_keys(v)
    else
      keys << k
    end
  end
  keys
end

describe Lolita::LocaleMerger do
  it "should merge locales" do
    original_lv_locale_file = File.expand_path(File.dirname(__FILE__) + '/../sample data/lv.yml')
    original_en_locale_file = File.expand_path(File.dirname(__FILE__) + '/../sample data/en.yml')
    FileUtils.copy(original_lv_locale_file, "lv.yml")
    FileUtils.copy(original_en_locale_file, "en.yml")
    merger = Lolita::LocaleMerger.new(["./lv.yml","./en.yml"],[:lv,:en])
    merger.merge
    lv_data = YAML::parse_file("lv.yml").transform["lv"]
    en_data = YAML::parse_file("en.yml").transform["en"]
    File.delete("lv.yml")
    File.delete("en.yml")
    lv_keys = fetch_keys lv_data
    en_keys = fetch_keys en_data

    # both files should have equal keys
    lv_keys.sort.should == en_keys.sort

    # check some values
    lv_data["articles"]["show"]["footer"].should == "Nu kaut kā jau iet"
    lv_data["articles"]["index"]["foo"].should == ""
    en_data["articles"]["single"]["items"].should be_a(Array)
    en_data["articles"]["single"]["songs"].should == ""
    en_data["articles"]["show"]["di vi"].should == ""
    
  end
end