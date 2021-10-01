class PostsController < ApplicationController
  before_action :authenticate_user!, only: [:create, :update]
  
  rescue_from Exception do |e|       # El rescue_from más arriba del archivo tiene menor prioridad
    render json: [error: e.message], status: :internal_error
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    render json: {error: e.message}, status: :unprocessable_entity
  end

  # GET /posts
  def index
    @posts = Post.where(published: true).includes(:user)
    if !params[:search].nil? && params[:search].present?
      @posts = PostsSearchService.search(@posts, params[:search])
    end
    render json: @posts, status: :ok
  end

  # GET /posts/{id}
  def show
    @post = Post.find(params[:id])
    if (@post.published? || (Current.user && @post.user.id == Current.user.id))
      render json: @post, status: :ok
    else
      render json: {error: 'Not Found'}, status: :not_found
    end
  end

  # POST /posts
  def create
    @post = Current.user.posts.create!(create_params)
    @post = Post.create!(create_params)
    render json: @post, status: :created
  end

  # PUT /posts/{id}
  def update
    @post = Current.user.posts.find(params[:id])
    @post.update!(update_params)
    render json:@post, status: :ok
  end

  private

  def create_params
    params.require(:post).permit(:title, :content, :published)
  end

  def update_params
    params.require(:post).permit(:title, :content, :published)
  end

  def authenticate_user!
    token_regex = /^Barer (\w+)$/
    headers = request.headers

    if headers['Authorization'].present? && headers['Authorization'].match(token_regex)
      token = headers['Authorization'].match(token_regex)[1]

      if (Current.user = User.find_by_auth_token(token))
        return 
      end
    end

    render json: {}, status: :unauthorized
  end
end
