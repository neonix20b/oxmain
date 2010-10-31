require 'digest/sha1'
class User < ActiveRecord::Base
  acts_as_taggable
  has_many :tasks
  has_many :invites
  has_many :posts
  has_many :supports
  has_many :comments
  has_many :polls
  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :login, :email, :message => " не может быть пустым"
  validates_format_of       :email, :message => " не похож на правильный", :with => /\A[A-Z0-9._%+-]+@[A-Z0-9.-]+.[A-Z]{2,4}\Z/i
  validates_format_of       :login, :message => " может содержать только латинские буквы и цифры", :with => /\A[a-zA-Z][0-9A-Za-z_\-]+\Z/i
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 1..40, :message => "Слишком короткий", :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login, :message => "Слишком короткий",    :within => 3..30
  validates_length_of       :email, :message => "Слишком короткий",    :within => 3..30
  validates_uniqueness_of   :login, :case_sensitive => false
  validates_uniqueness_of   :show_name, :case_sensitive => false, :allow_nil=>true, :allow_blank=>true
  before_save :encrypt_password

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find_by_login(login) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  protected
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end
    
    def password_required?
      crypted_password.blank? || !password.blank?
    end
end
