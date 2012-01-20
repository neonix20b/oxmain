ActionMailer::Base.smtp_settings = {  
  :address              => "smtp.gmail.com",  
  :port                 => 587,  
  :domain               => "oxnull.net",  
  :user_name            => "oxmain@oxnull.net",  
  :password             => "qwerty91",  
  :authentication       => "plain",  
  :enable_starttls_auto => true  
} 
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.default_url_options = { :host => 'oxnull.net' }
ActionMailer::Base.asset_host = "http://oxnull.net"
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.raise_delivery_errors = true