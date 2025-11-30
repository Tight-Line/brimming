# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    def show
      @stats = build_stats
      @recent_activity = build_recent_activity
      @system_health = build_system_health
    end

    private

    def build_stats
      {
        users: {
          total: User.count,
          this_week: User.where("created_at > ?", 1.week.ago).count,
          this_month: User.where("created_at > ?", 1.month.ago).count
        },
        questions: {
          total: Question.count,
          this_week: Question.where("created_at > ?", 1.week.ago).count,
          this_month: Question.where("created_at > ?", 1.month.ago).count
        },
        answers: {
          total: Answer.count,
          this_week: Answer.where("created_at > ?", 1.week.ago).count,
          solved: Answer.where(is_correct: true).count
        },
        comments: {
          total: Comment.count,
          this_week: Comment.where("created_at > ?", 1.week.ago).count
        },
        spaces: {
          total: Space.count,
          with_content: Space.joins(:questions).distinct.count
        }
      }
    end

    def build_recent_activity
      {
        questions: Question.includes(:user, :space).order(created_at: :desc).limit(5),
        answers: Answer.includes(:user, :question).order(created_at: :desc).limit(5)
      }
    end

    def build_system_health
      {
        sidekiq: sidekiq_health,
        embeddings: embeddings_health
      }
    end

    def sidekiq_health
      require "sidekiq/api"
      stats = Sidekiq::Stats.new
      processes = stats.processes_size
      {
        status: processes >= 1 ? :ok : :warning,
        processed: stats.processed,
        failed: stats.failed,
        enqueued: stats.enqueued,
        processes: processes,
        busy: stats.workers_size,
        queues: Sidekiq::Queue.all.map { |q| { name: q.name, size: q.size } }
      }
    rescue => e
      { status: :error, message: e.message }
    end

    def embeddings_health
      provider = EmbeddingProvider.enabled.first
      if provider.nil?
        return { status: :not_configured, message: "No embedding provider configured" }
      end

      embedded_count = Question.where.not(embedding: nil).count
      total_count = Question.count
      coverage = total_count > 0 ? (embedded_count.to_f / total_count * 100).round(1) : 0

      {
        status: coverage > 90 ? :ok : (coverage > 50 ? :warning : :building),
        provider: provider.name,
        embedded: embedded_count,
        total: total_count,
        coverage: coverage
      }
    rescue => e
      { status: :error, message: e.message }
    end
  end
end
