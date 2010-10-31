class Invite < ActiveRecord::Base
  belongs_to :user
  acts_as_taggable
  belongs_to :blog
end
