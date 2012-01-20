class Invite < ActiveRecord::Base
  belongs_to :profile
  acts_as_taggable
  belongs_to :blog
  has_many :comments
  before_destroy { |record| Comment.destroy_all "invite_id = #{record.id}"   }
  before_destroy { |record| Poll.destroy_all "obj_id = \"Invite_#{record.id}\""}
end
