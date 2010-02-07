class Support < ActiveRecord::Base
  #attr_accessible :money, :task, :user
  belongs_to :user
  has_many :comments
  before_destroy { |record| Comment.destroy_all "support_id = #{record.id}"   }
end
