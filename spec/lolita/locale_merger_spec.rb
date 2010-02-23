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
  before :each do
    @sample_data = File.expand_path(File.dirname(__FILE__) + '/../sample data')
  end
  
  it "should merge locales" do
    original_lv_locale_file = File.expand_path("#{@sample_data}/lv.yml")
    original_en_locale_file = File.expand_path("#{@sample_data}/en.yml")
    test_dir = "#{RAILS_ROOT}/tmp/locale_test"
    Dir.mkdir(test_dir)
    FileUtils.copy(original_lv_locale_file, "#{test_dir}/lv.yml")
    FileUtils.copy(original_en_locale_file, "#{test_dir}/en.yml")
    merger = Lolita::LocaleMerger.new(test_dir,[:lv,:en])
    merger.merge
    lv_data = YAML::parse_file("#{test_dir}/lv.yml").transform["lv"]
    en_data = YAML::parse_file("#{test_dir}/en.yml").transform["en"]
    File.delete("#{test_dir}/lv.yml")
    File.delete("#{test_dir}/en.yml")
    Dir.delete(test_dir)
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

  it "should return correct status report" do
    merger = Lolita::LocaleMerger.new(@sample_data,[:ru,:lt])
    out = merger.status_report
    out.strip.gsub("\n","").gsub("\t","").gsub(" ","").should == %^
    locales
      [E] ru.articles.show.di vi
      [E] ru.articles.show.footer
      [E] ru.articles.single.items
      [E] ru.articles.single.songs
    locales
      [E] lt.articles.index.foo
    ^.strip.gsub("\n","").gsub("\t","").gsub(" ","")
  end

  it "should create cached status file" do
    merger = Lolita::LocaleMerger.new(@sample_data,[:ru,:lt])
    File.delete(merger.locales_status) if File.exists?(merger.locales_status)
    merger.status_report_cached.should == merger.status_report
    before_recreate = Time.now
    merger.status_report_cached
    File.stat(merger.locales_status).atime.should < before_recreate
    File.delete(merger.locales_status)
    File.delete(merger.locales_zip)
  end

  it "should create valid zip file" do
    merger = Lolita::LocaleMerger.new(@sample_data,[:ru,:lt])
    merger.create_locale_zip
    Zip::Archive.open(merger.locales_zip) do |ar|
      ar.num_files.should == 6
    end
    File.delete(merger.locales_status)
    File.delete(merger.locales_zip)
  end

  it "should clone one locale to another" do
    merger = Lolita::LocaleMerger.new(@sample_data,[:ru,:lt])
    merger.clone :lv, :ee
    ee_yml = File.join(@sample_data,"ee.yml")
    File.exist?(ee_yml).should be_true
    ee_data = YAML::parse_file(ee_yml).transform["ee"]
    File.delete(ee_yml)
    ee_data["articles"]["list"]["rss"].should == "RSS barotnes"
  end
end