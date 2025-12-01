# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    def show
      @stats = build_stats
      @recent_activity = build_recent_activity
      @system_health = build_system_health
      @orphaned_articles = build_orphaned_articles
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
        },
        articles: {
          total: Article.count,
          this_week: Article.where("created_at > ?", 1.week.ago).count,
          orphaned: Article.left_outer_joins(:article_spaces).where(article_spaces: { id: nil }).count
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

      # Questions - count via chunks
      embedded_questions = Question.not_deleted.joins(:chunks).where(chunks: { embedding_provider_id: provider.id }).distinct.count
      total_questions = Question.not_deleted.count

      # Articles - count via chunks
      embedded_articles = Article.active.joins(:chunks).where(chunks: { embedding_provider_id: provider.id }).distinct.count
      total_articles = Article.active.count

      # Chunks
      total_chunks = Chunk.where(embedding_provider_id: provider.id).count

      # Overall coverage
      total_items = total_questions + total_articles
      embedded_items = embedded_questions + embedded_articles
      coverage = total_items > 0 ? (embedded_items.to_f / total_items * 100).round(1) : 0

      {
        status: coverage > 90 ? :ok : (coverage > 50 ? :warning : :building),
        provider: provider.name,
        questions_embedded: embedded_questions,
        questions_total: total_questions,
        articles_embedded: embedded_articles,
        articles_total: total_articles,
        chunks: total_chunks,
        coverage: coverage
      }
    rescue => e
      { status: :error, message: e.message }
    end

    def build_orphaned_articles
      Article.left_outer_joins(:article_spaces)
             .where(article_spaces: { id: nil })
             .includes(:user)
             .order(created_at: :desc)
             .limit(10)
    end
  end
end
