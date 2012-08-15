# -*- encoding : utf-8 -*-
require 'spec_helper'
require "cancan/matchers"

def set_commentable_data
  @ability = Ability.new(@user)

  @project = FactoryGirl.create(:project)
  @issue = FactoryGirl.create(:issue, :project_id => @project.id, :user => @user)

  @comment = FactoryGirl.create(:comment, :commentable => @issue, :user => @user, :project => @project)
  @stranger_comment = FactoryGirl.create(:comment, :commentable => @issue, :user => @stranger, :project => @project)

  any_instance_of(Project, :versions => ['v1.0', 'v2.0'])
end

describe Comment do
  before { stub_symlink_methods }
  context 'for global admin user' do
    before(:each) do
      @user = FactoryGirl.create(:admin)
      @stranger = FactoryGirl.create(:user)

      set_commentable_data
    end

    it 'should create comment' do
      @ability.should be_able_to(:create, @comment)
    end

    pending "sends an e-mail" do
      ActionMailer::Base.deliveries.last.to.include?(@stranger.email).should == true
    end

    it 'should update comment' do
      @ability.should be_able_to(:update, @comment)
    end

    it 'should update stranger comment' do
      @ability.should be_able_to(:update, @stranger_comment)
    end

    it 'should destroy own comment' do
      @ability.should be_able_to(:destroy, @comment)
    end

    it 'should destroy stranger comment' do
      @ability.should be_able_to(:destroy, @stranger_comment)
    end
  end

  context 'for project admin user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      @stranger = FactoryGirl.create(:user)

      set_commentable_data

      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
    end

    it 'should create comment' do
      @comment.user = @user
      @ability.should be_able_to(:create, @comment)
    end

    it 'should update comment' do
      @ability.should be_able_to(:update, @comment)
    end

    it 'should update stranger comment' do
      @ability.should be_able_to(:update, @stranger_comment)
    end

    it 'should not destroy comment' do
      @ability.should_not be_able_to(:destroy, @comment)
    end
  end

  context 'for project owner user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      @stranger = FactoryGirl.create(:user)

      set_commentable_data

      @project.owner = @user; @project.save
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
    end

    it 'should create comment' do
      @ability.should be_able_to(:create, @comment)
    end

    it 'should update comment' do
      @ability.should be_able_to(:update, @comment)
    end

    it 'should update stranger comment' do
      @ability.should be_able_to(:update, @stranger_comment)
    end

    it 'should not destroy comment' do
      @ability.should_not be_able_to(:destroy, @comment)
    end
  end

  context 'for simple user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      @stranger = FactoryGirl.create(:user)

      set_commentable_data
    end

    it 'should create comment' do
      @ability.should be_able_to(:create, @comment)
    end

    it 'should update comment' do
      @ability.should be_able_to(:update, @comment)
    end

    it 'should not update stranger comment' do
      @ability.should_not be_able_to(:update, @stranger_comment)
    end

    it 'should not destroy comment' do
      @ability.should_not be_able_to(:destroy, @comment)
    end

    context 'with mass assignment' do
      it 'should not be able to update commentable' do
        @comment.update_attributes({:commentable_type => 'Grit::Commit', :commentable_id => 0})
        @comment.reload.commentable_id.should eql @issue.id
        @comment.reload.commentable_type.should eql @issue.class.name
      end

      it 'should not be able to update owner' do
        @comment.should_not allow_mass_assignment_of :user_id
      end

      it 'should not be able to update project' do
        @comment.should_not allow_mass_assignment_of :project_id
      end
    end

  end
end
