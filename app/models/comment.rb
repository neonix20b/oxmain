class Comment < ActiveRecord::Base
  belongs_to :profile
  belongs_to :post
  belongs_to :support
  belongs_to :invite
end
