class Privatemessage < ActiveRecord::Base
belongs_to :profile, :foreign_key=>"profile_from"
end
