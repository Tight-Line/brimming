# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @recent_questions = recent_questions_for_user
    @spaces = Space.alphabetical
  end

  private

  # Returns recent questions, prioritizing subscribed spaces for logged-in users
  def recent_questions_for_user
    base_query = Question.not_deleted.includes(:user, :space)

    if current_user
      subscribed_space_ids = current_user.all_subscribed_spaces.pluck(:id)

      if subscribed_space_ids.any?
        # Order by: subscribed spaces first, then by created_at desc
        base_query
          .select(ActiveRecord::Base.sanitize_sql_array([ "questions.*, CASE WHEN space_id IN (?) THEN 0 ELSE 1 END AS subscription_order", subscribed_space_ids ]))
          .order(Arel.sql("subscription_order ASC, questions.created_at DESC"))
          .limit(10)
      else
        base_query.recent.limit(10)
      end
    else
      base_query.recent.limit(10)
    end
  end
end
