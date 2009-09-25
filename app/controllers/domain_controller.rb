require 'xmlrpc/client'
class DomainController < ApplicationController
  def chek

  end

  def create_domain
    server = XMLRPC::Client.new2("http://89.208.146.80:1979")
    t = server.call("reg_domain", 'sitecrafter.ru')
    render :text => t.to_s
  end
end
