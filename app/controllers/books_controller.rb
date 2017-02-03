class BooksController < ApplicationController
  # GET /books
  def index
    @books = current_user.books_tree
    @books = [current_user.books.build] if @books.empty?
  end

  # PATCH /books/update_all
  def update_all
    respond_to do |format|
      if current_user.update(current_user_books_params)
        format.html { redirect_to books_path, notice: 'As estratégias foram atualizadas com sucesso.' }
      else
        format.html { redirect_to books_path, alert: (current_user.errors.full_messages.join('. ') + '.') }
      end
    end
  end

  # GET /books/new
  def new
    @book = Book.new
  end

  # POST /books
  def create
    book = Book.new(book_params.merge(user_id: current_user.id))

    respond_to do |format|
      if book.save
        format.html { redirect_to books_path, notice: 'Estratégia criada com sucesso.' }
      else
        format.html { redirect_to books_path, alert: (book.errors.full_messages.join('. ') + '.') }
      end
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def book_params
      params.fetch(:book).permit(:name)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def current_user_books_params
      params.require(:user).permit(books_attributes: [:id, :parent_id, :position, :name, :_destroy])
    end
end
