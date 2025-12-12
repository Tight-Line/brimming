# frozen_string_literal: true

class SpacesController < ApplicationController
  before_action :require_login, except: [ :index, :show ]
  before_action :set_space, only: [ :show, :edit, :update, :destroy, :moderators, :add_moderator, :remove_moderator,
                                     :publishers, :add_publisher, :remove_publisher, :subscribe, :unsubscribe ]

  def index
    @spaces = policy_scope(Space)
                .alphabetical
                .left_joins(:article_spaces)
                .select("spaces.*, COUNT(DISTINCT article_spaces.article_id) AS articles_count_value")
                .group("spaces.id")
  end

  def show
    authorize @space
    @questions = @space.questions.not_deleted.recent.includes(:user)
    @articles = @space.articles.active.recent.includes(:user)
  end

  def new
    @space = Space.new
    authorize @space
  end

  def create
    @space = Space.new(space_params)
    authorize @space

    if @space.save
      redirect_to @space, notice: "Space created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @space
  end

  def update
    authorize @space

    if @space.update(space_params)
      redirect_to @space, notice: "Space updated successfully.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @space

    if @space.questions.exists?
      redirect_to @space, alert: "Cannot delete a space that contains questions."
    else
      @space.destroy!
      redirect_to spaces_path, notice: "Space deleted.", status: :see_other
    end
  end

  def moderators
    authorize @space, :manage_moderators?
    @moderators = @space.moderators
  end

  def add_moderator
    authorize @space, :manage_moderators?
    user = User.find(params[:user_id])
    @space.add_moderator(user)
    redirect_to moderators_space_path(@space), notice: "#{user.display_name} is now a moderator."
  end

  def remove_moderator
    authorize @space, :manage_moderators?
    user = User.find(params[:user_id])
    @space.remove_moderator(user)
    redirect_to moderators_space_path(@space), notice: "#{user.display_name} is no longer a moderator.", status: :see_other
  end

  def publishers
    authorize @space, :manage_publishers?
    @publishers = @space.publishers
  end

  def add_publisher
    authorize @space, :manage_publishers?
    user = User.find(params[:user_id])
    @space.add_publisher(user)
    redirect_to publishers_space_path(@space), notice: "#{user.display_name} is now a publisher."
  end

  def remove_publisher
    authorize @space, :manage_publishers?
    user = User.find(params[:user_id])
    @space.remove_publisher(user)
    redirect_to publishers_space_path(@space), notice: "#{user.display_name} is no longer a publisher.", status: :see_other
  end

  def subscribe
    authorize @space, :subscribe?
    SpaceSubscription.find_or_create_by!(user: current_user, space: @space)

    respond_to do |format|
      format.html { redirect_back fallback_location: @space, notice: "You are now subscribed to #{@space.name}." }
      format.turbo_stream
    end
  end

  def unsubscribe
    authorize @space, :unsubscribe?
    subscription = current_user.space_subscriptions.find_by(space: @space)
    subscription&.destroy

    respond_to do |format|
      format.html { redirect_back fallback_location: @space, notice: "You have unsubscribed from #{@space.name}." }
      format.turbo_stream
    end
  end

  private

  def set_space
    @space = Space.find_by!(slug: params[:id])
  end

  def space_params
    params.require(:space).permit(:name, :description, :qa_wizard_prompt, :rag_chunk_limit, :similar_questions_limit)
  end
end
