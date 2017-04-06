module BooksHelper
  def books_options_for_user
    options = []
    current_user.books_tree.each do |parent|
      if (children = parent.children).present?
        children.each do |child|
          options << ["#{parent.name} > #{child.name}", child.id]
        end
      else
        options << [parent.name, parent.id]
      end
    end
    options
  end
end
