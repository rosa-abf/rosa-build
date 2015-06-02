require 'spec_helper'

def set_commentable_data
  @project = FactoryGirl.create(:project)
  @issue = FactoryGirl.create(:issue, project_id: @project.id, user: @user)

  @comment = FactoryGirl.create(:comment, commentable: @issue, user: @user, project: @project)
  @stranger_comment = FactoryGirl.create(:comment, commentable: @issue, user: @stranger, project: @project)

  allow_any_instance_of(Project).to receive(:versions).and_return(%w(v1.0 v2.0))
end

def create_comment_in_issue issue, body
  FactoryGirl.create(:comment, user: issue.user, commentable: issue, project: issue.project, body: body)
end

describe Comment do
  before { stub_symlink_methods }

  context 'for simple user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      @stranger = FactoryGirl.create(:user)
      set_commentable_data
    end

    context 'automatic issue linking' do
      before(:each) do
        @same_name_project = FactoryGirl.create(:project, name: @project.name)
        @issue_in_same_name_project = FactoryGirl.create(:issue, project: @same_name_project, user: @same_name_project.owner)
        @another_project = FactoryGirl.create(:project, owner: @user)
        @other_user_project = FactoryGirl.create(:project)
        @issue = FactoryGirl.create(:issue, project: @project, user: @user)
        @second_issue = FactoryGirl.create(:issue, project: @project, user: @user)
        @issue_in_another_project = FactoryGirl.create(:issue, project: @another_project, user: @user)
        @issue_in_other_user_project = FactoryGirl.create(:issue, project: @other_user_project, user: @other_user_project.owner)
      end

      it 'should create automatic comment' do
        create_comment_in_issue(@issue, "test link to ##{@issue.serial_id}; [##{@second_issue.serial_id}]")
        expect(
          Comment.where(automatic: true, commentable_type: 'Issue',
                        commentable_id: @second_issue.id,
                        created_from_issue_id: @issue.id).count
        ).to eq(1)
      end

      it 'should not create automatic comment to the same issue' do
        create_comment_in_issue(@issue, "test link to ##{@issue.serial_id}; [##{@second_issue.serial_id}]")
        expect(
          Comment.where(automatic: true,
                        created_from_issue_id: @issue.id).count
        ).to eq(1)
      end

      it 'should create automatic comment in the another project issue' do
        body = "[#{@another_project.name_with_owner}##{@issue_in_another_project.serial_id}]"
        create_comment_in_issue(@issue, body)
        expect(
          Comment.where(automatic: true, commentable_type: 'Issue',
                        commentable_id: @issue_in_another_project.id,
                        created_from_issue_id: @issue.id).count
        ).to eq(1)
      end

      it 'should create automatic comment in the same name project issue' do
        body = "[#{@same_name_project.owner.uname}##{@issue_in_same_name_project.serial_id}]"
        create_comment_in_issue(@issue, body)
        expect(
          Comment.where(automatic: true, commentable_type: 'Issue',
                        commentable_id: @issue_in_same_name_project.id,
                        created_from_issue_id: @issue.id).count
        ).to eq(1)
      end

      it 'should not create duplicate automatic comment' do
        create_comment_in_issue(@issue, "test link to [##{@second_issue.serial_id}]")
        create_comment_in_issue(@issue, "test duplicate link to [##{@second_issue.serial_id}]")
        expect(
          Comment.where(automatic: true, commentable_type: 'Issue',
                        commentable_id: @second_issue.id,
                        created_from_issue_id: @issue.id).count
        ).to eq(1)
      end

      it 'should not create duplicate automatic comment from one' do
        create_comment_in_issue(@issue, "test link to [##{@second_issue.serial_id}]; ##{@second_issue.serial_id}")
        expect(
          Comment.where(automatic: true, commentable_type: 'Issue',
                        commentable_id: @second_issue.id,
                        created_from_issue_id: @issue.id).count
        ).to eq(1)
      end

      it 'should create two automatic comment' do
        body = "test ##{@second_issue.serial_id}" +
              " && [#{@another_project.name_with_owner}##{@issue_in_another_project.serial_id}]"
        create_comment_in_issue(@issue, body)
        expect(Comment.where(automatic: true,
                             created_from_issue_id: @issue.id).count).to eq(2)
      end

      it 'should create automatic comment by issue title' do
        issue = FactoryGirl.create(:issue, project: @project, user: @user,
                                   title: "link to ##{@issue.serial_id}")
        expect(Comment.where(automatic: true,
                             created_from_issue_id: issue.id).count).to eq(1)
      end

      it 'should create automatic comment from issue body' do
        issue = FactoryGirl.create(:issue, project: @project, user: @user,
                                   body: "link to ##{@issue.serial_id}")
        expect(Comment.where(automatic: true,
                             created_from_issue_id: issue.id).count).to eq(1)
      end

      it 'should create only one automatic comment from issue title and body' do
        issue = FactoryGirl.create(:issue, project: @project, user: @user,
                                   title: "link to ##{@issue.serial_id} in title",
                                   :body  => "link to ##{@issue.serial_id} in body")
        expect(Comment.where(automatic: true,
                             created_from_issue_id: issue.id).count).to eq(1)
      end
    end
  end
end
