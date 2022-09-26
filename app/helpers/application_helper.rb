module ApplicationHelper
  def page_title(page_title = '', admin: false)
    base_title = if admin
                   '抹茶と神社。(管理画面)'
                 else
                   '抹茶と神社。'
                 end
    page_title.empty? ? base_title : "#{base_title}|#{page_title}"
  end

  def active_if(path)
    path == controller_path ? 'active' : ''
  end
end
