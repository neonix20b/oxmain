module FlexHelper
  def site_url(usr)
    lnk = usr.login + '.oxnull.net'
    lnk = usr.domain if usr.domain and usr.domain.size > 3
    return lnk;
  end
end
