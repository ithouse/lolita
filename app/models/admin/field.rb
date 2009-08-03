class Admin::Field < Cms::Base
  set_table_name :admin_fields

  validates_presence_of :table,:name
  named_scope :by_table, lambda{|table|
    {:conditions=>["`table`=?",table]}
  }
  named_scope :by_field, lambda{|field|
    {:conditions=>["`name`=?",field]}
  }

  def self.remove_by_table(table)
    self.by_table(table).each{|field| field.destroy }
  end

  def self.by_table_and_field(table,field)
    fields=self.by_table(table).by_field(field.to_s)
    !fields.empty? && fields.first.human_name.to_s.size>0 ? fields.first.human_name : field.to_s.humanize
  end
end
