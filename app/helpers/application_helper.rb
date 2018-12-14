module ApplicationHelper
  def page_title
    case controller_name
    when 'transactions'
      'Operações'
    end
  end
end
