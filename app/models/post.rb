class Post < ActiveRecord::Base
  attr_accessible :title, :text, :blog, :last_comment
  belongs_to :blog
  belongs_to :user
  has_many :comments
  acts_as_taggable
  before_destroy { |record| Comment.destroy_all "post_id = #{record.id}"   }
end
