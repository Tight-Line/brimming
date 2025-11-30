# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  describe "GET /admin" do
    context "when not logged in" do
      it "redirects to root" do
        get admin_root_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "when logged in as regular user" do
      before { sign_in regular_user }

      it "redirects to root with access denied" do
        get admin_root_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when logged in as admin" do
      before { sign_in admin }

      it "renders the dashboard" do
        get admin_root_path
        expect(response).to have_http_status(:ok)
      end

      it "includes user stats" do
        create_list(:user, 3)
        get admin_root_path
        expect(response.body).to include("Users")
      end

      it "includes question stats" do
        space = create(:space)
        create(:question, space: space, user: admin)
        get admin_root_path
        expect(response.body).to include("Questions")
      end

      it "includes answer stats" do
        space = create(:space)
        question = create(:question, space: space, user: admin)
        create(:answer, question: question, user: admin)
        get admin_root_path
        expect(response.body).to include("Answers")
      end

      it "includes comment stats" do
        space = create(:space)
        question = create(:question, space: space, user: admin)
        create(:comment, commentable: question, user: admin)
        get admin_root_path
        expect(response.body).to include("Comments")
      end

      it "includes space stats" do
        create(:space)
        get admin_root_path
        expect(response.body).to include("Spaces")
      end

      it "includes recent activity" do
        space = create(:space)
        question = create(:question, space: space, user: admin, title: "Recent question title here")
        create(:answer, question: question, user: admin)
        get admin_root_path
        expect(response.body).to include("Recent question title here")
      end

      it "includes system health status" do
        get admin_root_path
        expect(response.body).to include("System Health")
      end

      context "with embedding provider configured" do
        let!(:provider) { create(:embedding_provider, enabled: true) }

        it "shows embedding health" do
          get admin_root_path
          expect(response.body).to include(provider.name)
        end

        it "shows embedding coverage percentage" do
          space = create(:space)
          create(:question, space: space, user: admin)
          get admin_root_path
          # The view shows coverage as a percentage
          expect(response.body).to include("%")
        end
      end

      context "without embedding provider" do
        it "shows not configured status" do
          get admin_root_path
          # Check for the actual text in the view
          expect(response.body).to include("Not Configured")
        end
      end

      context "with sidekiq stats" do
        it "shows sidekiq health" do
          get admin_root_path
          expect(response.body).to include("Sidekiq")
        end
      end

      context "with no sidekiq processes" do
        before do
          mock_stats = instance_double(Sidekiq::Stats,
            processes_size: 0,
            workers_size: 0,
            processed: 100,
            failed: 0,
            enqueued: 0
          )
          allow(Sidekiq::Stats).to receive(:new).and_return(mock_stats)
          allow(Sidekiq::Queue).to receive(:all).and_return([])
        end

        it "shows sidekiq warning status" do
          get admin_root_path
          expect(response.body).to include("0 processes")
        end
      end

      context "with sidekiq processes running" do
        before do
          mock_stats = instance_double(Sidekiq::Stats,
            processes_size: 2,
            workers_size: 1,
            processed: 100,
            failed: 0,
            enqueued: 0
          )
          allow(Sidekiq::Stats).to receive(:new).and_return(mock_stats)
          allow(Sidekiq::Queue).to receive(:all).and_return([])
        end

        it "shows sidekiq ok status" do
          get admin_root_path
          expect(response.body).to include("2 processes")
        end
      end

      context "with sidekiq queues" do
        before do
          mock_stats = instance_double(Sidekiq::Stats,
            processes_size: 1,
            workers_size: 0,
            processed: 50,
            failed: 0,
            enqueued: 5
          )
          mock_queue = instance_double(Sidekiq::Queue, name: "default", size: 5)
          allow(Sidekiq::Stats).to receive(:new).and_return(mock_stats)
          allow(Sidekiq::Queue).to receive(:all).and_return([ mock_queue ])
        end

        it "shows queue information" do
          get admin_root_path
          expect(response.body).to include("default")
          expect(response.body).to include("5")
        end
      end

      context "with sidekiq error" do
        before do
          allow(Sidekiq::Stats).to receive(:new).and_raise(StandardError.new("Connection refused"))
        end

        it "shows sidekiq error status" do
          get admin_root_path
          expect(response.body).to include("Error")
        end
      end

      context "with embedding provider error" do
        let!(:provider) { create(:embedding_provider, enabled: true) }

        before do
          # Stub where.not to raise an error only for the embeddings check
          # Use a specific relation double that raises on count
          error_relation = double("relation")
          allow(error_relation).to receive(:count).and_raise(StandardError.new("Embedding check failed"))

          # Allow normal where calls but make where.not raise
          allow(Question).to receive(:where).and_call_original
          allow_any_instance_of(ActiveRecord::QueryMethods::WhereChain).to receive(:not).and_return(error_relation)
        end

        it "shows embedding error status" do
          get admin_root_path
          expect(response.body).to include("Error")
        end
      end


      context "with high embedding coverage" do
        let!(:provider) { create(:embedding_provider, enabled: true) }

        before do
          space = create(:space)
          # Create a question with embedding set
          q = create(:question, space: space, user: admin)
          q.update_columns(embedding: Array.new(1536) { rand }, embedded_at: Time.current)
        end

        it "shows ok status for high coverage" do
          get admin_root_path
          expect(response.body).to include("100")
        end
      end

      context "with medium embedding coverage" do
        let!(:provider) { create(:embedding_provider, enabled: true) }

        before do
          space = create(:space)
          # Create 5 questions, 3 with embeddings (60% coverage, which triggers :warning)
          3.times do
            q = create(:question, space: space, user: admin)
            q.update_columns(embedding: Array.new(1536) { rand }, embedded_at: Time.current)
          end
          2.times { create(:question, space: space, user: admin) }
        end

        it "shows warning status for medium coverage" do
          get admin_root_path
          expect(response.body).to include("60")
        end
      end

      context "with low embedding coverage" do
        let!(:provider) { create(:embedding_provider, enabled: true) }

        before do
          space = create(:space)
          # Create 4 questions, 1 with embedding (25% coverage, which triggers :building)
          q = create(:question, space: space, user: admin)
          q.update_columns(embedding: Array.new(1536) { rand }, embedded_at: Time.current)
          3.times { create(:question, space: space, user: admin) }
        end

        it "shows building status for low coverage" do
          get admin_root_path
          expect(response.body).to include("25")
        end
      end
    end
  end
end
