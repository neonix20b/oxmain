require 'digest/sha1'
class User < ActiveRecord::Base
  acts_as_taggable
  belongs_to :profile
  has_many :tasks
  self.record_timestamps = false
  # Virtual attribute for the unencrypted password

  validates_presence_of     :oxdomain, :message => " не может быть пустым"
#  validates_format_of       :email, :message => " не похож на правильный", :with => /\A[A-Z0-9._%+-]+@[A-Z0-9.-]+.[A-Z]{2,4}\Z/i
  validates_format_of       :oxdomain, :message => " может содержать только латинские буквы и цифры", :with => /\A[a-zA-Z][0-9A-Za-z_\-]+\Z/i
#  validates_presence_of     :password,                   :if => :password_required?
#  validates_presence_of     :password_confirmation,      :if => :password_required?
#  validates_length_of       :password, :within => 1..40, :message => "Слишком короткий", :if => :password_required?
#  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :oxdomain, :message => "Слишком короткий",    :within => 3..30
#  validates_length_of       :email, :message => "Слишком короткий",    :within => 3..30
  validates_uniqueness_of   :oxdomain, :case_sensitive => false
#  validates_uniqueness_of   :show_name, :case_sensitive => false, :allow_nil=>true, :allow_blank=>true
#  before_save :encrypt_password

	def disk_current_size
		return 1024
	end
	def disk_max_size
		return 1024
	end
	def mysql_current_size
		return 1024
	end
	def mysql_max_size
		return 1024
	end
end
