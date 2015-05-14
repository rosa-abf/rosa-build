require 'spec_helper'

# shared_examples_for 'able search' do
#   it 'should be able to search' do
#     get :index
#     expect(response).to be_success
#     expect(response).to render_template(:index)
#   end
# end
# shared_examples_for 'not able search' do
#   it 'should not be able to search' do
#     get :index
#     expect(response).to redirect_to(controller.current_user ? forbidden_path : new_user_session_path)
#   end
# end

describe HomeController, type: :controller do
  before { stub_symlink_methods }

  context 'as guest' do
    %i(activity own_activity issues pull_requests).each do |action|
      it "should redirect to new session page from #{action} action" do
        get action
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  context 'as user' do
    before do
      @user = FactoryGirl.create(:user)
      set_session_for @user
    end

    %i(activity own_activity issues pull_requests).each do |action|
      it "should able to get #{action}" do
        get action
        expect(response).to be_success
      end
    end

    context 'check activity feed' do
      before do
        @issue        = FactoryGirl.create(:issue)
        @user_comment = FactoryGirl.create(:comment, user: @user, commentable: @issue)
        @comment      = FactoryGirl.create(:comment, commentable: @issue)
      end

      it 'activity page should contain only another user action' do
        get :activity
        expect(assigns(:activity_feeds).where(creator_id: @user).exists?).to be_falsy
      end

      it 'activity page should contain record about comment' do
        get :activity
        expect(
          assigns(:activity_feeds)
         .where(kind: 'new_comment_notification', creator_id: @comment.user).first
         .data[:comment_id] == @comment.id
        ).to be_truthy
      end

      it 'activity page should not contain record about own comment' do
        get :activity
        expect(
          assigns(:activity_feeds)
         .where(kind: 'new_comment_notification', creator_id: @user).exists?
        ).to be_falsy
      end

      it 'activity page should contain only elements for current user' do
        get :activity
        expect(assigns(:activity_feeds).where.not(user_id: @user).exists?).to be_falsy
      end

      it 'own activity page should contain only current user action' do
        get :own_activity
        expect(assigns(:activity_feeds).where.not(creator_id: @user).exists?).to be_falsy
      end

      it "own activity page should not contain record about another user's comment" do
        get :own_activity
        expect(
          assigns(:activity_feeds)
         .where(kind: 'new_comment_notification', creator_id: @comment.user).exists?
        ).to be_falsy
      end

      it 'own activity page should contain record about own comment' do
        get :own_activity
        expect(
          assigns(:activity_feeds)
         .where(kind: 'new_comment_notification', creator_id: @user).exists?
        ).to be_truthy
      end
    end
  end
end
