require 'spec_helper'
require "cancan/matchers"

def set_comments_data_for_commit
  @ability = Ability.new(@user)

  @project = Factory(:project, :owner => @user)
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
      #~ #@project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'admin')
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

    context 'for default settings' do
      it 'should send an e-mail' do
        ActionMailer::Base.deliveries = []
        comment = Comment.create(:user => @stranger, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@user.email).should == true
      end
    end

    context 'for disabled notify setting new_comment_commit_repo_owner' do
      it 'should not send an e-mail' do
        ActionMailer::Base.deliveries = []
        @user.notifier.update_attribute :new_comment_commit_repo_owner, false
        comment = Comment.create(:user => @stranger, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 0
      end
    end

    context 'for disabled notify setting new_comment_commit_owner' do
      it 'should send an e-mail' do
        ActionMailer::Base.deliveries = []
        @user.notifier.update_attribute :new_comment_commit_owner, false
        comment = Comment.create(:user => @stranger, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@user.email).should == true
      end
    end

    context 'for disabled notify setting new_comment_commit_commentor' do
      it 'should send an e-mail' do
        ActionMailer::Base.deliveries = []
        @user.notifier.update_attribute :new_comment_commit_commentor, false
        comment = Comment.create(:user => @stranger, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@user.email).should == true
      end
    end

    context 'for disabled all notify setting expect global' do
      it 'should not send an e-mail' do
        ActionMailer::Base.deliveries = []
        @user.notifier.update_attribute :new_comment_commit_repo_owner, false
        @user.notifier.update_attribute :new_comment_commit_owner, false
        @user.notifier.update_attribute :new_comment_commit_commentor, false
        comment = Comment.create(:user => @stranger, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 0
      end
    end

    context 'for unsubscribe commit' do
      it 'should not send an e-mail' do
        ActionMailer::Base.deliveries = []
        Subscribe.set_subscribe(@project, @commit, @user.id, Subscribe::OFF)
        comment = Comment.create(:user => @stranger, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 0 # cache project.commit_comments_subscribes ...
      end
    end

    context 'for disabled global notify setting' do
      it 'should not send an e-mail' do
        ActionMailer::Base.deliveries = []
        @user.notifier.update_attribute :can_notify, false
        comment = Comment.create(:user => @stranger, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 0
      end
    end

  end

  context 'for project owner user' do
    before(:each) do
      @user = Factory(:user)
      @stranger = Factory(:user)

      set_comments_data_for_commit

      @project.update_attribute(:owner, @user)
      #@project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'admin')
    end

    it 'should create comment' do
      @ability.should be_able_to(:create, Comment.create(@create_params))
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
        ActionMailer::Base.deliveries = []
        comment = Comment.create(:user => @stranger, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@project.owner.email).should == true
      end
    end

    context 'for disabled notify setting new_comment_commit_repo_owner' do
      it 'should not send an e-mail' do
        ActionMailer::Base.deliveries = []
        @user.notifier.update_attribute :new_comment_commit_repo_owner, false
        comment = Comment.create(:user => @stranger, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 0
      end
    end

    context 'for disabled notify setting new_comment_commit_owner' do
      it 'should send an e-mail' do
        ActionMailer::Base.deliveries = []
        @user.notifier.update_attribute :new_comment_commit_owner, false
        comment = Comment.create(:user => @stranger, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 1 # cache project.commit_comments_subscribes ...
        ActionMailer::Base.deliveries.last.to.include?(@user.email).should == true
      end
    end

    context 'for disabled notify setting new_comment_commit_commentor' do
      it 'should send an e-mail' do
        ActionMailer::Base.deliveries = []
        @user.notifier.update_attribute :new_comment_commit_commentor, false
        comment = Comment.create(:user => @stranger, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 1 # cache project.commit_comments_subscribes ...
        ActionMailer::Base.deliveries.last.to.include?(@user.email).should == true
      end
    end

    context 'for disabled all notify setting expect global' do
      it 'should not send an e-mail' do
        ActionMailer::Base.deliveries = []
        @user.notifier.update_attribute :new_comment_commit_repo_owner, false
        @user.notifier.update_attribute :new_comment_commit_owner, false
        @user.notifier.update_attribute :new_comment_commit_commentor, false
        comment = Comment.create(:user => @stranger, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 0
      end
    end

    context 'for unsubscribe project' do
      it 'should not send an e-mail' do
        ActionMailer::Base.deliveries = []
        Subscribe.set_subscribe(@project, @commit, @user.id, Subscribe::OFF)
        comment = Comment.create(:user => @stranger, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 0
      end
    end

    context 'for disabled global notify setting' do
      it 'should not send an e-mail' do
        ActionMailer::Base.deliveries = []
        @user.notifier.update_attribute :can_notify, false
        comment = Comment.create(:user => @stranger, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 0
      end
    end

    context 'for own commit' do
      it 'should send a one e-mail' do
        ActionMailer::Base.deliveries = []
        @project.owner.update_attribute :email, 'code@tpope.net'
        comment = Comment.create(:user => @stranger, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)

        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@project.owner.email).should == true
      end
    end

  end

  context 'for simple user' do
    before(:each) do
      @user = Factory(:user)
      @simple = Factory(:user)
      @stranger = Factory(:user)
      set_comments_data_for_commit
      @create_params = {:commentable_type => @commit.class.name, :commentable_id => @commit.id,
        :user => @simple, :project => @project}
      @comment = Factory(:comment, :user => @simple)
      @comment.update_attributes(:commentable_type => @commit.class.name, :commentable_id => @commit.id)
      @ability = Ability.new(@simple)
    end

    it 'should create comment' do
      @ability.should be_able_to(:create, Comment.create(@create_params))
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
      it 'should not send an e-mail' do
        ActionMailer::Base.deliveries = []
        comment = Comment.create(:user => @stranger, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@stranger.email).should == false
      end

      it 'should send an e-mail for comments after his comment' do
        comment = Comment.create(:user => @simple, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)

        ActionMailer::Base.deliveries = []
        comment = Comment.create(:user => @user, :body => 'owner comment', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@simple.email).should == true
      end

      it 'should send an e-mail when subscribed to project' do
        ActionMailer::Base.deliveries = []
        @project.owner.notifier.update_attribute :can_notify, false
        @stranger.notifier.update_attribute :new_comment_commit_repo_owner, false
        @stranger.notifier.update_attribute :new_comment_commit_owner, false
        #@stranger.notifier.update_attribute :new_comment_commit_commentor, false

        Subscribe.set_subscribe(@project, @commit, @stranger.id, Subscribe::ON)
        comment = Comment.create(:user => @project.owner, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@stranger.email).should == true
      end

      it 'should not send an e-mail for own comment' do
        ActionMailer::Base.deliveries = []
        #@project.owner.notifier.update_attribute :can_notify, false
        Subscribe.set_subscribe(@project, @commit, @stranger.id, Subscribe::ON)
        comment = Comment.create(:user => @owner, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 0
      end
    end

    context 'for committer' do
      it 'should send an e-mail' do
        ActionMailer::Base.deliveries = []
        @stranger.update_attribute :email, 'code@tpope.net'
        comment = Comment.create(:user => @user, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@stranger.email).should == true
      end

      it 'should send a one e-mail when subscribed to commit' do
        ActionMailer::Base.deliveries = []
        Subscribe.set_subscribe(@project, @commit, @stranger.id, Subscribe::ON)
        @stranger.update_attribute :email, 'code@tpope.net'
        comment = Comment.create(:user => @user, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@stranger.email).should == true
      end

      it 'should not send an e-mail for own comment' do
        ActionMailer::Base.deliveries = []
        #@project.owner.notifier.update_attribute :can_notify, false
        @stranger.update_attribute :email, 'code@tpope.net'
        comment = Comment.create(:user => @stranger, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@stranger.email).should == false
      end

      it 'should not send an e-mail if global notify off' do
        ActionMailer::Base.deliveries = []
        @project.owner.notifier.update_attribute :can_notify, false
        @stranger.update_attribute :email, 'code@tpope.net'
        @stranger.notifier.update_attribute :can_notify, false
        comment = Comment.create(:user => @user, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 0
      end

      it 'should not send an e-mail if notify for my commits off' do
        ActionMailer::Base.deliveries = []
        @stranger.notifier.update_attribute :new_comment_commit_owner, false
        @stranger.update_attribute :email, 'code@tpope.net'
        comment = Comment.create(:user => @user, :body => 'hello!', :project => @project,
            :commentable_type => @commit.class.name, :commentable_id => @commit.id)
        ActionMailer::Base.deliveries.count.should == 0
      end
    end
  end
end