module ApplicationHelper
  # 各ページのタイトル設定
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

  def default_meta_tags
    {
      site: '抹茶と神社。',
      title: '京都の抹茶スイーツ店と神社仏閣の検索サービス',
      reverse: true,
      charset: 'utf-8',
      description: '抹茶と神社。は京都の抹茶スイーツ店と神社仏閣を検索でき、それぞれの近くにあるスポットを簡単に検索できるサービスです。',
      keywords: '抹茶スイーツ,神社仏閣,京都',
      canonical: request.original_url,
      separator: '|',
      noindex: !Rails.env.production?,
      og: {
        site_name: :site,
        title: :title,
        description: :description,
        type: 'website',
        url: request.original_url,
        image: image_url('ogp.png'),
        locale: 'ja_JP'
      },
      twitter: {
        card: 'summary_large_image',
        site: '@@hiiragi_mattya',
        image: image_url('ogp.png')
      }
    }
  end
end
