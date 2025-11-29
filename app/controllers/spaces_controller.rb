# frozen_string_literal: true

class SpacesController < ApplicationController
  before_action :require_login, except: [ :index, :show ]
  before_action :set_space, only: [ :show, :edit, :update, :destroy, :moderators, :add_moderator, :remove_moderator ]

  def index
    @spaces = policy_scope(Space).alphabetical
  end

  def show
    authorize @space
    @questions = @space.questions.not_deleted.recent.includes(:user)
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

  private

  def set_space
    @space = Space.find_by!(slug: params[:id])
  end

  def space_params
    params.require(:space).permit(:name, :description)
  end
end
