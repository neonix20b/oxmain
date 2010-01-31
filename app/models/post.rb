class Post < ActiveRecord::Base
  attr_accessible :title, :text, :blog
  belongs_to :blog
  belongs_to :user
  has_many :comments
  acts_as_taggable
end
