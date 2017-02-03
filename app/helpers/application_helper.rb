module ApplicationHelper
  APP_VERSION = `git log --pretty=%H`.split("\n").first

  # Build a breadcrumb hash
  URLS = Rails.application.routes.url_helpers
  BREADCRUMB = {
    'dashboard#index' => [{ content: 'Início', active: true }],
    'books#index' => [{ content: 'Estratégias' },
                      { content: 'Configuração', active: true}],
    'books#new' => [{ content: 'Estratégias', href: URLS.books_path },
                    { content: 'Nova estratégia', active: true}]
  }

  def app_version
    APP_VERSION
  end

  def menu_link_to(content, controller, action, active=nil)
    if active.nil?
      # evaluate if controller and action match the current ones
      active = (controller_name == controller && action_name == action)
    end
    url = url_for(controller: controller, action: action)
    html_class = 'nav-link'
    html_class += ' active' if active
    link_to content.html_safe, url, class: html_class
  end
end
