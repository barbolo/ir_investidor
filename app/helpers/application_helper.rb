module ApplicationHelper
  BREADCRUMB = {
    'dashboard#index' => [{content: 'Início', active: true}]
  }

  def app_version
    Rails.cache.fetch('app_version') do
      `git log --pretty=%H`.split("\n").first
    end
  end
end
