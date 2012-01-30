# -*- encoding : utf-8 -*-
require 'spec_helper'
require "cancan/matchers"

def set_comments_data_for_commit
  @ability = Ability.new(@user)

  @project = Factory(:project)
  %x(cp -Rf #{Rails.root}/spec/tests.git/* #{@project.git_repository.path}) # maybe FIXME ?
  @commit = @project.git_repository.commits.first

  @comment = Factory(:comment, :user => @user)
  @comment.update_attributes(:commentable_type => @commit.class.name, :commentable_id => @commit.id)

  @stranger_comment = Factory(:comment, :user => @stranger)
  @stranger_comment.update_attributes(:commentable_type => @commit.class.name, :commentable_id => @commit.id, :project => @project)

  @create_params = {:commentable_type => @commit.class.name, :commentable_id => @commit.id, :user => @user, :project => @project}

  any_instance_of(Project, :versions => ['v1.0', 'v2.0'])
end

describe Comment do
  context 'for global admin user' do
    before(:each) do
      @user = Factory(:admin)
      @stranger = Factory(:user)

      set_comments_data_for_commit
    end

    it 'should create comment' do
      @ability.should be_able_to(:create, Comment.new(@create_params))
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
      @user = Factory(:user)
      @stranger = Factory(:user)

      set_comments_data_for_commit

      @project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'admin')
    end

    it 'should create comment' do
      @ability.should be_able_to(:create, Comment.new(@create_params))
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
      @user = Factory(:user)
      @stranger = Factory(:user)

      set_comments_data_for_commit

      @project.update_attribute(:owner, @user)
      @project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'admin')
    end

    it 'should create comment' do
      @ability.should be_able_to(:create, Comment.new(@create_params))
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
      @user = Factory(:user)
      @stranger = Factory(:user)

      set_comments_data_for_commit
    end

    it 'should create comment' do
      @ability.should be_able_to(:create, Comment.new(@create_params))
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
  end
end
