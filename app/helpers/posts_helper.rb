module PostsHelper
  def add_favorite(blog_id)
    return "" if not logged_in?
    blog_id=blog_id.to_s
    return "<span>[в избранном]</span>" if current_user.favorite.split(',').include?(blog_id)
    return "<span id='blog_#{blog_id}'>#{rlink("[в избранное]",{:controller=>'main',:action=>'favorite', :blog_id=>blog_id},'blog_'+blog_id, 'post')}</span>"
  end

  def tag_links(obj)
    return "нет" if obj.tag_list.empty?
    ret = ''
    obj.tag_list.each do |tag|
      ret = ret + link_to(tag, blog_posts_path(0, :favorite => tag)) + ', '
    end
    ret.chomp!(", ")
    return ret
  end
end
