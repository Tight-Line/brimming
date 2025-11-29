# frozen_string_literal: true

class QuestionsController < ApplicationController
  before_action :require_login, only: [ :new, :create, :edit, :update, :destroy, :hard_delete, :upvote, :downvote, :remove_vote ]
  before_action :set_question, only: [ :show, :edit, :update, :destroy, :hard_delete, :upvote, :downvote, :remove_vote ]

  def index
    @questions = policy_scope(Question).recent.includes(:user, :space)
    @questions = @questions.by_space(Space.find_by(slug: params[:space])) if params[:space].present?
  end

  def show
    authorize @question
    if @question.deleted?
      redirect_to questions_path, alert: "This question has been deleted."
      return
    end
    @answers = @question.answers.by_votes.includes(:user, comments: [ :user, { replies: :user } ])
    @question_comments = @question.comments.top_level.includes(:user, replies: [ :user, { replies: :user } ]).recent
  end

  def new
    @question = Question.new
    authorize @question
    @spaces = Space.alphabetical
  end

  def create
    @question = current_user.questions.build(question_params)
    authorize @question

    if @question.save
      redirect_to @question, notice: "Question posted successfully."
    else
      @spaces = Space.alphabetical
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @question
    @spaces = Space.alphabetical
  end

  def update
    authorize @question
    if @question.update(question_params)
      @question.record_edit!(current_user)
      redirect_to @question, notice: "Question updated successfully.", status: :see_other
    else
      @spaces = Space.alphabetical
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @question
    @question.soft_delete!
    redirect_to questions_path, notice: "Question deleted.", status: :see_other
  end

  def hard_delete
    authorize @question
    @question.destroy!
    redirect_to questions_path, notice: "Question permanently deleted.", status: :see_other
  end

  def upvote
    authorize @question, :vote?
    @question.upvote_by(current_user)
    respond_to_vote
  end

  def downvote
    authorize @question, :vote?
    @question.downvote_by(current_user)
    respond_to_vote
  end

  def remove_vote
    authorize @question, :vote?
    @question.remove_vote_by(current_user)
    respond_to_vote
  end

  private

  def set_question
    @question = Question.find_by!(slug: params[:id])
  end

  def question_params
    params.require(:question).permit(:title, :body, :space_id)
  end

  def respond_to_vote
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "question-#{@question.id}-votes",
          partial: "votes/vote_buttons",
          locals: { votable: @question, votable_type: "question" }
        )
      end
      format.html { redirect_to @question }
    end
  end
end
