module ApplicationHelper
  APP_VERSION = `git log --pretty=%H`.split("\n").first
  BREADCRUMB = {
    'dashboard#index' => [{content: 'Início', active: true}]
  }

  def app_version
    APP_VERSION
  end
end
