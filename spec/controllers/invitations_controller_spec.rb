# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe InvitationsController, type: :controller do
  before do
    @past = create(:event, past: true)
    @current = create(:event, current: true)
    @future = create(:event, future: true)
  end

  describe 'GET #index' do
    it 'redirects to #new' do
      get :index
      expect(response).to redirect_to(invitations_new_path)
    end
  end

  describe 'GET #new' do
    before :each do
      get :new
    end

    it 'responds with success code' do
      expect(response).to be_successful
    end

    it 'renders :new template' do
      expect(response).to render_template(:new)
    end

    it 'assigns future events to @events' do
      expect(assigns(:events)).to include(@future)
      expect(assigns(:events)).not_to include(@current)
      expect(assigns(:events)).not_to include(@past)
    end

    it 'assigns InvitationForm to @invitation' do
      expect(assigns(:invitation)).to be_a(InvitationForm)
    end
  end

  describe 'POST #create' do
    before do
      authenticate_for_controllers
      @user.admin!
      @event = @future
      @event.memberships.destroy_all
      @membership = create(:membership, event: @event, attendance: 'Invited')
      @form_params = {'invitation': {
          'event': @event.code,
          'email': @membership.person.email
      }}
    end

    it 'assigns @invitation using params' do
      post :create, params: @form_params
      expect(assigns(:invitation)).to be_a(InvitationForm)
    end

    context 'valid params' do
      before do
        post :create, params: @form_params
      end

      it 'redirects to invitations_new_path' do
        expect(response).to redirect_to(invitations_new_path)
      end

      it 'assigns success message' do
        expect(flash[:success]).to be_present
      end

      it 'does not assign @events' do
        expect(assigns(:events)).to be_falsey
      end

      it 'does not add errors to @invitation' do
        expect(assigns(:invitation).errors).to be_empty
      end

      it 'sends invitation' do
        invitation = spy('invitation')
        allow(Invitation).to receive(:new).and_return(invitation)

        post :create, params: @form_params

        expect(invitation).to have_received(:send_invite)
      end
    end

    context 'invalid params' do
      before do
        @form_params = {'invitation' => {'event' => 'foo', 'email' => 'bar'}}
        post :create, params: @form_params
      end

      it 'assigns @events' do
        expect(assigns(:events)).not_to be_empty
      end

      it 'renders :new template' do
        expect(response).to render_template(:new)
      end

      it 'adds errors to @invitation' do
        expect(assigns(:invitation).errors).not_to be_empty
      end

      it 'does not send invitation' do
        invitation = spy('invitation')
        allow(Invitation).to receive(:new).and_return(invitation)

        post :create, params: @form_params

        expect(invitation).not_to have_received(:send_invite)
      end
    end
  end
end
