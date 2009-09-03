class MetaData < Cms::Base
  #belongs_to :menu_items
  belongs_to :metaable, :polymorphic => true
  #validates_uniqueness_of   :url, :scope => [:metaable_type], :case_sensitive => false ,:allow_blank=>true
  #validates_presence_of :title, :tags
  before_save :normalize_url
  translates :title,:url,:tags,:description
  #TODO test
  def self.find_by_object object
    self.find(:first,:conditions=>["metaable_id=? AND metaable_type=?",object.id,object.class.to_s])
  end
  
  def self.by_metaable id,class_name
    conditions=["metaable_type=?",class_name.to_s.camelize]
    if id.is_a?(Integer)
      conditions[0]<<"AND metaable_id=?"
      conditions<<id
    elsif id.is_a?(String)
      conditions[0]<<"AND #{self.table_name}.url=?"
      conditions<<id
    else
      conditions[0]<<"AND metaable_id IS NULL"
    end
    self.find(:first,:conditions=>conditions)
  end

  def self.find_title id, controller
    md=MetaData.find(:first,:conditions=>["metaable_id=? AND metaable_type=?",id,controller.to_s.camelize])
    md.title if md && md.title && md.title.size>0
  end

  def self.url_match query="",conditions=[]
    query=query.to_s
    start_with=self.find(:all,:conditions=>self.cms_merge_conditions(["url LIKE ?","#{query}%"],conditions), :limit=>50)
    include_query=unless start_with.size==50
      self.find(:all,:conditions=>self.cms_merge_conditions(["url LIKE ?","%#{query}%"],conditions),:limit=>50-start_with.size)
    else
      []
    end
    (start_with+include_query).collect{|m| m.url}
  end

  private
  def normalize_url
    self.url.gsub!(/^\W+|\W+$/,'')
    self.url=self.url.to_url
    self.url.downcase!
    #make urls unique per metaable_type
    url_not_unique = true
    first_try = true
    count=2
    while url_not_unique
      conditions=["metaable_type=? AND url=? #{new_record? ? "" : "AND id<>?"}",self.metaable_type,self.url]
      conditions<<self.id unless new_record?
      res = MetaData.find(:all,:conditions=>conditions)
      if res.size == 0
        url_not_unique = false
      else
        if first_try
          self.url += '-2'
          first_try = false
        else
          self.url.slice!(self.url.size-(count.to_s.size)..self.url.size)
          count+=1
          self.url += count.to_s
          
        end
      end
    end
  end

  def delete_older
    md=MetaData.find(:all,:conditions=>["metaable_id=? AND metaable_type=?",self.metaable_id,self.metaable_type])
    md.each{|item|
      item.destroy
      MetaData.delete(item.id)
    }
  end
end
