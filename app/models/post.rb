class Post < ActiveRecord::Base
  attr_accessible :title, :text, :blog, :last_comment
  belongs_to :blog
  belongs_to :user
  belongs_to :profile
  has_many :comments
  acts_as_taggable
  before_destroy { |record| Comment.destroy_all "post_id = #{record.id}"   }
  validates_presence_of     :title, :message => " не может быть пустым"
  validates_length_of       :title, :message => "Заголовок не соответствует правильной длинне",    :within => 5..250
  self.record_timestamps = false
end
