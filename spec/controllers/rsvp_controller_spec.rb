# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe RsvpController, type: :controller do
  before do
    @invitation = create(:invitation)
    @membership = @invitation.membership
    @membership.attendance = 'Invited'
    @membership.save
    allow_any_instance_of(LegacyConnector).to receive(:update_member)
  end

  describe 'GET #index' do
    context 'without one-time-password (OTP) in the url' do
      it 'redirects to new invitations page' do
        get :index
        expect(response).to redirect_to(invitations_new_path)
      end
    end

    context 'with a valid OTP in the url' do
      it 'validates the OTP via local db and renders index' do
        get :index, { otp: @invitation.code }

        expect(assigns(:invitation)).to eq(@invitation)
        expect(response).to render_template(:index)
      end

      it 'validates the OTP via legacy db' do
        allow_any_instance_of(InvitationChecker).to receive(:check_legacy_database).and_return(@invitation)

        get :index, { otp: '123' }

        expect(assigns(:invitation)).to eq(@invitation)
        expect(response).to render_template(:index)
      end
    end

    context 'with an invalid OTP in the url' do
      it 'sets error message' do
        lc = FakeLegacyConnector.new
        expect(LegacyConnector).to receive(:new).and_return(lc)
        allow(lc).to receive(:check_rsvp).with('123').and_return(lc.invalid_otp)

        get :index, { otp: '123' }

        expect(assigns(:invitation)).to be_a(InvitationChecker)
        expect(response).to render_template("rsvp/_invitation_errors")
      end
    end
  end

  describe 'GET #no' do
    it 'renders no template' do
      get :no, { otp: @invitation.code }
      expect(response).to render_template(:no)
    end
  end

  describe 'POST #no' do
    it 'changes membership attendance to Declined' do
      post :no, { otp: @invitation.code, organizer_message: 'Hi' }

      expect(Membership.find(@membership.id).attendance).to eq('Declined')
    end

    it 'forwards to feedback form' do
      post :maybe, { otp: @invitation.code, organizer_message: 'Hi' }

      expect(response).to redirect_to(rsvp_feedback_path(@membership.id))
    end
  end

  describe 'GET #maybe' do
    it 'renders maybe template' do
      get :maybe, { otp: @invitation.code }
      expect(response).to render_template(:maybe)
    end
  end

  describe 'POST #maybe' do
    it 'changes membership attendance to Undecided' do
      post :maybe, { otp: @invitation.code, organizer_message: 'Hi' }

      expect(Membership.find(@membership.id).attendance).to eq('Undecided')
    end

    it 'forwards to feedback form' do
      post :maybe, { otp: @invitation.code, organizer_message: 'Hi' }

      expect(response).to redirect_to(rsvp_feedback_path(@membership.id))
    end
  end

  describe 'GET #feedback' do
    it 'renders feedback template' do
      get :feedback, { membership_id: @membership.id }
      expect(response).to render_template(:feedback)
    end
  end

  describe 'POST #feedback' do
    it 'forwards to event membership page' do
      post :feedback, { membership_id: @membership.id, feedback_message: 'Hi' }

      expect(response).to redirect_to(event_memberships_path(@membership.event))
    end
  end
end