require 'spec_helper'

def set_data_for_pull
  @ability = Ability.new(@user)

  @project = FactoryGirl.create(:project_with_commit, owner: @user)

  @clone_path = File.join(APP_CONFIG['root_path'], 'repo_clone', @project.id.to_s)
  FileUtils.mkdir_p(@clone_path)

  @other_project = FactoryGirl.create(:project_with_commit, owner: @user)

  any_instance_of(Project, versions: ['v1.0', 'v2.0'])
end

describe PullRequest do
  before { stub_symlink_methods }

  context 'for owner user' do
    before do
      @user = FactoryGirl.create(:user)
      set_data_for_pull
      @pull = @project.pull_requests.new(issue_attributes: {title: 'test', body: 'testing'})
      @pull.issue.user, @pull.issue.project = @user, @pull.to_project
      @pull.to_ref = 'master'
      @pull.from_project, @pull.from_ref = @project, 'non_conflicts'
      @pull.save

      @other_pull = @project.pull_requests.new(issue_attributes: {title: 'test_other', body: 'testing_other'})
      @other_pull.issue.user, @other_pull.issue.project = @user, @other_pull.to_project
      @other_pull.to_ref = 'master'
      @other_pull.from_project, @other_pull.from_ref = @other_project, 'non_conflicts'
      @other_pull.save
    end

    it 'ensures that path to pull_request repository has been changed after rename of project' do
      @pull.check
      @project.update_attributes(name: "#{@project.name}-new")
      @pull.reload
      Dir.exists?(@pull.path).should be_truthy
    end

    it 'master should merge with non_conflicts branch' do
      @pull.check
      @pull.status.should == 'ready'
    end

    it 'master should not merge with conflicts branch' do
      @pull.from_ref = 'conflicts'
      @pull.check
      @pull.status.should == 'blocked'
    end

    it 'should already merged when already up-to-date branches' do
      @pull.from_ref = 'master'
      @pull.check
      @pull.status.should == 'merged'
    end

    context 'for other head project' do
      it 'master should merge with non_conflicts branch' do
        @other_pull.check
        @other_pull.status.should == 'ready'
      end

      it 'master should not merge with conflicts branch' do
        @other_pull.from_ref = 'conflicts'
        @other_pull.check
        @other_pull.status.should == 'blocked'
      end

      it 'should already merged when already up-to-date branches' do
        @other_pull.from_ref = 'master'
        @other_pull.check
        @other_pull.status.should == 'merged'
      end
    end

    it "should not create same pull" do
      @same_pull = @project.pull_requests.new(issue_attributes: {title: 'same', body: 'testing'})
      @same_pull.issue.user, @same_pull.issue.project = @user, @same_pull.to_project
      @same_pull.to_ref = 'master'
      @same_pull.from_project, @same_pull.from_ref = @project, 'non_conflicts'
      @same_pull.save
      @project.pull_requests.joins(:issue).where(issues: {title: @same_pull.title}).count.should == 0
    end

    it "should not create pull with wrong base ref" do
      @wrong_pull = @project.pull_requests.new(issue_attributes: {title: 'wrong base', body: 'testing'})
      @wrong_pull.issue.user, @wrong_pull.issue.project = @user, @wrong_pull.to_project
      @wrong_pull.to_ref = 'wrong'
      @wrong_pull.from_project, @wrong_pull.from_ref = @project, 'non_conflicts'
      @wrong_pull.save
      @project.pull_requests.joins(:issue).where(issues: {title: @wrong_pull.title}).count.should == 0
    end

    it "should not create pull with wrong head ref" do
      @wrong_pull = @project.pull_requests.new(issue_attributes: {title: 'wrong head', body: 'testing'})
      @wrong_pull.issue.user, @wrong_pull.issue.project = @user, @wrong_pull.to_project
      @wrong_pull.to_ref = 'master'
      @wrong_pull.from_project, @wrong_pull.from_ref = @project, 'wrong'
      @wrong_pull.save
      @project.pull_requests.joins(:issue).where(issues: {title: @wrong_pull.title}).count.should == 0
    end

    it "should create pull with tag" do
      system("cd #{@project.path} && git tag 4.7.5.3 $(git rev-parse #{@pull.from_ref})") # TODO REDO through grit
      @pull = @project.pull_requests.new(issue_attributes: {title: 'tag', body: 'testing'})
      @pull.issue.user, @pull.issue.project = @user, @pull.to_project
      @pull.to_ref = 'master'
      @pull.from_project, @pull.from_ref = @project, '4.7.5.3'
      @pull.save
      @project.pull_requests.joins(:issue).where(issues: {title: @pull.title}).count.should == 1
    end

    it "should close pull when deleting from branch" do
      system("cd #{@project.path} && git branch -D #{@pull.from_branch}")
      @pull.check
      @project.pull_requests.joins(:issue).where(issues: {title: @pull.title, status: 'closed'}).count.should == 1
    end
  end

  before do
    FileUtils.rm_rf(APP_CONFIG['root_path'])
  end

  it { should belong_to(:issue).validate(true) }
  it { should belong_to(:to_project) }
  it { should belong_to(:from_project) }

  context '#update_statistic' do
    let(:issue)         { FactoryGirl.build(:issue) }
    let(:pull_request)  { FactoryGirl.build(:pull_request, issue: issue) }

    it 'updates styatistics' do
      allow(PullRequest).to receive(:check_ref).and_return(true)
      issue.new_pull_request = true
      expect do
        pull_request.save
      end.to change(Statistic, :count).by(1)
      expect(Statistic.last.key).to eq "#{Statistic::KEY_PULL_REQUEST}.#{Issue::STATUS_OPEN}"
    end
  end

  after do
    FileUtils.rm_rf(APP_CONFIG['root_path'])
    FileUtils.rm_rf File.join(Rails.root, "tmp", Rails.env, "pull_requests")
  end
end
