module PostsHelper
  def add_favorite(blog,only_add=false)
    return "" if not logged_in?
    blog_id=blog.id.to_s
	if not current_profile.favorite.nil? and current_profile.favorite.split(',').include?(blog_id)
		return "| <span id='blog_#{blog_id}'>#{rlink("Больше не следить за блогом \"#{blog.name}\"",{:controller=>'main',:action=>'favorite', :blog_id=>blog_id},'blog_'+blog_id, 'post')}</span>" if not only_add
		return ""
	else
		return "| <span id='blog_#{blog_id}'>#{rlink("Следить за блогом \"#{blog.name}\"",{:controller=>'main',:action=>'favorite', :blog_id=>blog_id},'blog_'+blog_id, 'post')}</span>"
	end
  end

  def tag_links(obj)
    return "нет" if obj.tag_list.empty?
    ret = ''
    obj.tag_list.each do |tag|
      ret = ret + link_to(tag, url_for(:controller=>'posts',:blog_id=>tag)) + ', '
    end
    ret.chomp!(", ")
    return ret
  end
end
