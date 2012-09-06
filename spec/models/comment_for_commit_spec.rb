# -*- encoding : utf-8 -*-
require 'spec_helper'
require "cancan/matchers"

def create_comment user
  FactoryGirl.create(:comment, :user => user, :commentable => @commit, :project => @project)
end

def set_comments_data_for_commit
  @ability = Ability.new(@user)

  @project = FactoryGirl.create(:project, :owner => @user)
  %x(cp -Rf #{Rails.root}/spec/tests.git/* #{@project.repo.path}) # maybe FIXME ?
  @commit = @project.repo.commits.first

  @comment = create_comment(@user)
  @stranger_comment = create_comment(@stranger)

  @subscribe_params = {:project_id => @project.id, :subscribeable_id => @commit.id.hex, :subscribeable_type => @commit.class.name}
  Subscribe.destroy_all

  any_instance_of(Project, :versions => ['v1.0', 'v2.0'])
end

describe Comment do
  before { stub_symlink_methods }
  context 'for global admin user' do
    before(:each) do
      @user = FactoryGirl.create(:admin)
      @stranger = FactoryGirl.create(:user)

      set_comments_data_for_commit
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

      set_comments_data_for_commit
      @admin = FactoryGirl.create(:user)
      @ability = Ability.new(@admin)
      @project.relations.create!(:actor_type => 'User', :actor_id => @admin.id, :role => 'admin')
      ActionMailer::Base.deliveries = []
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

    context 'for default settings' do
      it 'should not send an e-mail' do
        comment = create_comment(@stranger)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@user.email).should == true
      end
    end

    context 'for disabled notify setting new_comment_commit_repo_owner' do
      it 'should not send an e-mail' do
        @user.notifier.update_column :new_comment_commit_repo_owner, false
        comment = create_comment(@stranger)
        ActionMailer::Base.deliveries.count.should == 1
      end
    end

    context 'for disabled notify setting new_comment_commit_owner' do
      it 'should send an e-mail' do
        @user.notifier.update_column :new_comment_commit_owner, false
        comment = create_comment(@stranger)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@user.email).should == true
      end
    end

    context 'for disabled notify setting new_comment_commit_commentor' do
      it 'should send an e-mail' do
        @user.notifier.update_column :new_comment_commit_commentor, false
        comment = create_comment(@stranger)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@user.email).should == true
      end
    end

    context 'for disabled all notify setting expect global' do
      it 'should not send an e-mail' do
        @user.notifier.update_column :new_comment_commit_repo_owner, false
        @user.notifier.update_column :new_comment_commit_owner, false
        @user.notifier.update_column :new_comment_commit_commentor, false
        comment = create_comment(@stranger)
        ActionMailer::Base.deliveries.count.should == 0
      end
    end

    context 'for unsubscribe commit' do
      it 'should not send an e-mail' do
        Subscribe.unsubscribe_from_commit @subscribe_params.merge(:user_id => @user.id)
        comment = create_comment(@stranger)
        ActionMailer::Base.deliveries.count.should == 0
      end
    end

    context 'for disabled global notify setting' do
      it 'should not send an e-mail' do
        @user.notifier.update_column :can_notify, false
        comment = create_comment(@stranger)
        ActionMailer::Base.deliveries.count.should == 0
      end
    end

  end

  context 'for project owner user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      @stranger = FactoryGirl.create(:user)
      set_comments_data_for_commit
      
      @project.owner = @user
      @project.save
      
      ActionMailer::Base.deliveries = []
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

    context 'for default enabled settings' do
      it 'should send an e-mail by default settings' do
        comment = create_comment(@stranger)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@project.owner.email).should == true
      end
    end

    context 'for disabled notify setting new_comment_commit_repo_owner' do
      it 'should not send an e-mail' do
        @user.notifier.update_column :new_comment_commit_repo_owner, false
        Comment.destroy_all
        comment = create_comment(@stranger)
        ActionMailer::Base.deliveries.count.should == 0
      end
    end

    context 'for disabled notify setting new_comment_commit_owner' do
      it 'should send an e-mail' do
        @user.notifier.update_column :new_comment_commit_owner, false
        comment = create_comment(@stranger)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@user.email).should == true
      end
    end

    context 'for disabled notify setting new_comment_commit_commentor' do
      it 'should send an e-mail' do
        @user.notifier.update_column :new_comment_commit_commentor, false
        comment = create_comment(@stranger)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@user.email).should == true
      end
    end

    context 'for disabled all notify setting expect global' do
      it 'should not send an e-mail' do
        @user.notifier.update_column :new_comment_commit_repo_owner, false
        @user.notifier.update_column :new_comment_commit_owner, false
        @user.notifier.update_column :new_comment_commit_commentor, false
        comment = create_comment(@stranger)
        ActionMailer::Base.deliveries.count.should == 0
      end
    end

    context 'for unsubscribe project' do
      it 'should not send an e-mail' do
        Subscribe.unsubscribe_from_commit @subscribe_params.merge(:user_id => @user.id)
        comment = create_comment(@stranger)
        ActionMailer::Base.deliveries.count.should == 0
      end
    end

    context 'for disabled global notify setting' do
      it 'should not send an e-mail' do
        @user.notifier.update_column :can_notify, false
        comment = create_comment(@stranger)
        ActionMailer::Base.deliveries.count.should == 0
      end
    end

    context 'for own commit' do
      it 'should send a one e-mail' do
        @project.owner.update_column :email, 'code@tpope.net'
        comment = create_comment(@stranger)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@project.owner.email).should == true
      end
    end

  end

  context 'for simple user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      @simple = FactoryGirl.create(:user)
      @stranger = FactoryGirl.create(:user)
      set_comments_data_for_commit
      @comment = create_comment(@simple)
      @ability = Ability.new(@simple)
      ActionMailer::Base.deliveries = []
      Subscribe.unsubscribe_from_commit @subscribe_params.merge(:user_id => [@stranger.id, @project.owner.id])
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

    context 'for default enabled settings' do
      it 'should send an e-mail' do
        comment = create_comment(@stranger)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@simple.email).should == true
      end

      it 'should send an e-mail for comments after his comment' do
        comment = create_comment(@simple)
        ActionMailer::Base.deliveries = []
        comment = create_comment(@user)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@simple.email).should == true
      end

      it 'should send an e-mail when subscribed to project' do
        Subscribe.subscribe_to_commit @subscribe_params.merge(:user_id => @simple.id)
        comment = create_comment(@project.owner)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@simple.email).should == true
      end

      it 'should not send an e-mail for own comment' do
        comment = create_comment(@simple)
        ActionMailer::Base.deliveries.count.should == 0
      end
    end

    context 'for committer' do
      it 'should send an e-mail' do
        @simple.update_column :email, 'code@tpope.net'
        comment = create_comment(@user)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@simple.email).should == true
      end

      it 'should send a one e-mail when subscribed to commit' do
        Subscribe.subscribe_to_commit @subscribe_params.merge(:user_id => @simple.id)
        @simple.update_column :email, 'code@tpope.net'
        comment = create_comment(@user)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@simple.email).should == true
      end

      it 'should not send an e-mail for own comment' do
        @simple.update_column :email, 'code@tpope.net'
        comment = create_comment(@simple)
        ActionMailer::Base.deliveries.count.should == 0
      end

      it 'should not send an e-mail if global notify off' do
        @project.owner.notifier.update_column :can_notify, false
        @simple.update_column :email, 'code@tpope.net'
        @simple.notifier.update_column :can_notify, false
        comment = create_comment(@user)
        ActionMailer::Base.deliveries.count.should == 0
      end

      it 'should not send an e-mail if notify for my commits off' do
        Comment.destroy_all
        @simple.notifier.update_column :new_comment_commit_owner, false
        @simple.update_column :email, 'code@tpope.net'
        comment = create_comment(@user)
        ActionMailer::Base.deliveries.count.should == 0
      end
    end
  end
end
