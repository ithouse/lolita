class Admin::Token < Cms::Base
  set_table_name :admin_tokens
  belongs_to :user, :class_name=>"Admin::User"
  belongs_to :portal, :class_name=>"Admin::Portal"

  cattr_accessor :current_token

  def set_user(user)
    self.user=user
    self.save!
  end

  def adopt_params(adoptee)
    self.uri = adoptee.uri
    self.portal = adoptee.portal
    #self.class.delete(self.id)
    self
  end

  def cleanup
    return if self.user.nil?
    self.class.destroy_all [ "(id != ? AND user_id = ?) OR (updated_at<?)", self.id, self.user_id,1.day.ago ]
  end

end
