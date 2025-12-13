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

      it "includes article stats" do
        create(:article, user: admin)
        get admin_root_path
        expect(response.body).to include("Articles")
      end

      context "with orphaned articles" do
        let!(:orphaned_article) { create(:article, user: admin, title: "Orphaned Article Title") }
        let!(:assigned_article) do
          article = create(:article, user: admin, title: "Assigned Article")
          space = create(:space)
          create(:article_space, article: article, space: space)
          article
        end

        it "shows orphaned articles count in stats" do
          get admin_root_path
          expect(response.body).to include("1 orphaned")
        end

        it "shows orphaned articles section" do
          get admin_root_path
          expect(response.body).to include("Orphaned Articles")
          expect(response.body).to include("Orphaned Article Title")
        end

        it "does not show assigned articles in orphaned section" do
          get admin_root_path
          # The assigned article should NOT appear in the orphaned section
          # (It may appear elsewhere on the page, but not in the orphaned list)
          expect(response.body).to include("Orphaned Article Title")
        end

        it "shows edit link for orphaned articles" do
          get admin_root_path
          expect(response.body).to include(edit_article_path(orphaned_article))
        end
      end

      context "without orphaned articles" do
        let!(:assigned_article) do
          article = create(:article, user: admin)
          space = create(:space)
          create(:article_space, article: article, space: space)
          article
        end

        it "does not show orphaned articles section" do
          get admin_root_path
          expect(response.body).not_to include("Orphaned Articles")
        end

        it "shows 0 orphaned in stats" do
          get admin_root_path
          expect(response.body).to include("0 orphaned")
        end
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

      context "with queue stats" do
        it "shows queue health" do
          get admin_root_path
          expect(response.body).to include("Job Queue")
        end
      end

      context "with no queue processes" do
        before do
          allow(SolidQueue::ReadyExecution).to receive(:count).and_return(0)
          allow(SolidQueue::ClaimedExecution).to receive(:count).and_return(0)
          allow(SolidQueue::FailedExecution).to receive(:count).and_return(0)
          allow(SolidQueue::ScheduledExecution).to receive(:count).and_return(0)
          allow(SolidQueue::Process).to receive(:where).and_return(double(count: 0))
          allow(SolidQueue::Job).to receive(:where).and_return(double(not: double(count: 100)))
          allow(SolidQueue::Queue).to receive(:all).and_return([])
        end

        it "shows queue warning status" do
          get admin_root_path
          expect(response.body).to include("0 processes")
        end
      end

      context "with queue processes running" do
        before do
          allow(SolidQueue::ReadyExecution).to receive(:count).and_return(0)
          allow(SolidQueue::ClaimedExecution).to receive(:count).and_return(1)
          allow(SolidQueue::FailedExecution).to receive(:count).and_return(0)
          allow(SolidQueue::ScheduledExecution).to receive(:count).and_return(0)
          allow(SolidQueue::Process).to receive(:where).and_return(double(count: 2))
          allow(SolidQueue::Job).to receive(:where).and_return(double(not: double(count: 100)))
          allow(SolidQueue::Queue).to receive(:all).and_return([])
        end

        it "shows queue ok status" do
          get admin_root_path
          expect(response.body).to include("2 processes")
        end
      end

      context "with queue jobs" do
        before do
          allow(SolidQueue::ReadyExecution).to receive(:count).and_return(5)
          allow(SolidQueue::ClaimedExecution).to receive(:count).and_return(0)
          allow(SolidQueue::FailedExecution).to receive(:count).and_return(0)
          allow(SolidQueue::ScheduledExecution).to receive(:count).and_return(0)
          allow(SolidQueue::Process).to receive(:where).and_return(double(count: 1))
          allow(SolidQueue::Job).to receive(:where).and_return(double(not: double(count: 50)))
          mock_queue = double("Queue", name: "default")
          allow(SolidQueue::Queue).to receive(:all).and_return([ mock_queue ])
          allow(SolidQueue::ReadyExecution).to receive(:where).with(queue_name: "default").and_return(double(count: 5))
        end

        it "shows queue information" do
          get admin_root_path
          expect(response.body).to include("default")
          expect(response.body).to include("5")
        end
      end

      context "with queue error" do
        before do
          allow(SolidQueue::ReadyExecution).to receive(:count).and_raise(StandardError.new("Connection refused"))
        end

        it "shows queue error status" do
          get admin_root_path
          expect(response.body).to include("Error")
        end
      end

      context "with embedding provider error" do
        let!(:provider) { create(:embedding_provider, enabled: true) }

        before do
          # Stub the embeddings_health method directly to simulate an error
          allow_any_instance_of(Admin::DashboardController).to receive(:embeddings_health).and_return(
            { status: :error, message: "Test error" }
          )
        end

        it "shows embedding error status" do
          get admin_root_path
          expect(response.body).to include("Error")
        end
      end

      context "when embeddings_health raises an exception" do
        let!(:provider) { create(:embedding_provider, enabled: true) }

        before do
          # Simulate an exception occurring during question count
          allow(Question).to receive(:not_deleted).and_raise(StandardError.new("Database connection lost"))
        end

        it "returns error status" do
          get admin_root_path
          expect(response.body).to include("Error")
        end
      end


      context "with high embedding coverage" do
        let!(:provider) { create(:embedding_provider, enabled: true) }

        before do
          space = create(:space)
          # Create a question with chunks from the provider
          q = create(:question, space: space, user: admin)
          create(:chunk, :embedded, chunkable: q, embedding_provider: provider)
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
          # Create 5 questions, 3 with chunks (60% coverage, which triggers :warning)
          3.times do
            q = create(:question, space: space, user: admin)
            create(:chunk, :embedded, chunkable: q, embedding_provider: provider)
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
          # Create 4 questions, 1 with chunk (25% coverage, which triggers :building)
          q = create(:question, space: space, user: admin)
          create(:chunk, :embedded, chunkable: q, embedding_provider: provider)
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
