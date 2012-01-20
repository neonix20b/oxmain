class Profile < ActiveRecord::Base
  has_many :users
  has_many :invites
  has_many :posts
  has_many :polls
  has_many :comments
  has_many :privatemessages, :foreign_key=>"profile_from"
  self.record_timestamps = false
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, :registerable,
		:recoverable, :rememberable, :trackable, 
		:validatable, :lockable,  :confirmable,
		:token_authenticatable
	validates_uniqueness_of   :show_name, :case_sensitive => false

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :show_name, :avatar
  scope :adepts, where(:adept => true)
end
