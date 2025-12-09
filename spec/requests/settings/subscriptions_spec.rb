# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Settings::Subscriptions" do
  let(:user) { create(:user) }
  let(:ldap_user) { create(:user, provider: "ldap", uid: "testuser", ldap_dn: "uid=testuser,ou=users,dc=example,dc=com") }
  let(:space) { create(:space) }
  let(:ldap_server) { create(:ldap_server) }

  describe "GET /settings/subscriptions" do
    context "when not logged in" do
      it "redirects to login" do
        get settings_subscriptions_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in with no subscriptions" do
      before { sign_in user }

      it "returns http success" do
        get settings_subscriptions_path
        expect(response).to have_http_status(:success)
      end

      it "displays empty state" do
        get settings_subscriptions_path
        expect(response.body).to include("My Subscriptions")
        expect(response.body).to include("not subscribed to any spaces")
      end
    end

    context "when logged in with manual subscriptions" do
      before do
        sign_in user
        create(:space_subscription, user: user, space: space)
      end

      it "displays the subscribed space" do
        get settings_subscriptions_path
        expect(response.body).to include(space.name)
        expect(response.body).to include("Manual")
      end
    end

    context "when logged in as LDAP user with LDAP subscriptions" do
      let(:mapping) do
        m = create(:ldap_group_mapping, ldap_server: ldap_server, group_pattern: "cn=engineers")
        m.spaces << space
        m
      end

      before do
        sign_in ldap_user
        mapping # Create the mapping
        allow_any_instance_of(Settings::SubscriptionsController).to receive(:session).and_return({ ldap_server_id: ldap_server.id })
      end

      it "displays LDAP subscriptions with group name" do
        get settings_subscriptions_path
        expect(response.body).to include(space.name)
        expect(response.body).to include("LDAP:")
        expect(response.body).to include("cn=engineers")
      end

      context "when opted out of LDAP space" do
        before do
          SpaceOptOut.create!(user: ldap_user, space: space, ldap_group_mapping: mapping)
        end

        it "shows opted out badge" do
          get settings_subscriptions_path
          expect(response.body).to include("Opted out")
          expect(response.body).to include("Re-subscribe")
        end
      end
    end

    context "when user has both manual and LDAP subscriptions" do
      let(:manual_space) { create(:space, name: "Manual Space") }
      let(:ldap_space) { create(:space, name: "LDAP Space") }
      let(:mapping) do
        m = create(:ldap_group_mapping, ldap_server: ldap_server)
        m.spaces << ldap_space
        m
      end

      before do
        sign_in ldap_user
        create(:space_subscription, user: ldap_user, space: manual_space)
        mapping
        allow_any_instance_of(Settings::SubscriptionsController).to receive(:session).and_return({ ldap_server_id: ldap_server.id })
      end

      it "displays both types of subscriptions" do
        get settings_subscriptions_path
        expect(response.body).to include("Manual Space")
        expect(response.body).to include("LDAP Space")
      end
    end

    context "when same space is both manual and LDAP assigned" do
      let(:shared_space) { create(:space, name: "Shared Space") }
      let(:mapping) do
        m = create(:ldap_group_mapping, ldap_server: ldap_server)
        m.spaces << shared_space
        m
      end

      before do
        sign_in ldap_user
        create(:space_subscription, user: ldap_user, space: shared_space)
        mapping
        allow_any_instance_of(Settings::SubscriptionsController).to receive(:session).and_return({ ldap_server_id: ldap_server.id })
      end

      it "shows the space only once (as manual subscription, skips duplicate LDAP)" do
        get settings_subscriptions_path
        # The space should only appear once in subscription-item elements
        # The link text shows the space name, so it appears once per subscription
        doc = Nokogiri::HTML(response.body)
        subscription_items = doc.css(".subscription-item")
        expect(subscription_items.count).to eq(1)
        expect(response.body).to include("Manual")
        expect(response.body).not_to include("LDAP:")
      end
    end

    context "LDAP user without ldap_dn" do
      let(:ldap_user_no_dn) { create(:user, provider: "ldap", uid: "nodn", ldap_dn: nil) }

      before { sign_in ldap_user_no_dn }

      it "handles missing ldap_dn gracefully" do
        get settings_subscriptions_path
        expect(response).to have_http_status(:success)
      end
    end

    context "LDAP user with non-existent server in session" do
      before do
        sign_in ldap_user
        allow_any_instance_of(Settings::SubscriptionsController).to receive(:session).and_return({ ldap_server_id: 99999 })
      end

      it "handles missing server gracefully" do
        get settings_subscriptions_path
        expect(response).to have_http_status(:success)
      end
    end
  end
end
