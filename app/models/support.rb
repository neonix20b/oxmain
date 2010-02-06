class Support < ActiveRecord::Base
  #attr_accessible :money, :task, :user
  belongs_to :user
  has_many :comments
end
