require 'spec_helper'
require "cancan/matchers"

def admin_create
	@admin = Factory(:admin)
  @ability = Ability.new(@admin)
end

def user_create
	@user = Factory(:user)
  @ability = Ability.new(@user)
end

def guest_create
  @ability = Ability.new(User.new)
end

describe CanCan do

	let(:personal_platform) { Factory(:platform, :platform_type => 'personal') }
	let(:personal_repository) { Factory(:repository, :platform_type => 'personal') }
	let(:open_platform) { Factory(:platform, :visibility => 'open') }
	let(:hidden_platform) { Factory(:platform, :visibility => 'hidden') }

	context 'Site admin' do
		before(:each) do
			admin_create
		end
		
		it 'should manage all' do
			#(@ability.can? :manage, :all).should be_true
			@ability.should be_able_to(:manage, :all)
		end

		it 'should not be able to destroy personal platforms' do
			@ability.should_not be_able_to(:destroy, personal_platform)
		end

		it 'should not be able to destroy personal repositories' do
			@ability.should_not be_able_to(:destroy, personal_repository)
		end

	end

	context 'Site guest' do

		before(:each) do
			guest_create
		end

		it 'should be able to read open platform' do
			@ability.should be_able_to(:read, open_platform)
		end

		it 'should not be able to read hidden platform' do
			@ability.should_not be_able_to(:read, hidden_platform)
		end

		it 'should be able to auto build projects' do
			@ability.should be_able_to(:auto_build, Project)
		end

		[:status_build, :pre_build, :post_build, :circle_build, :new_bbdt].each do |action|
			it "should be able to #{ action } build list" do
				@ability.should be_able_to(action, BuildList)
			end
		end

		it 'should be able to register new user' do
			@ability.should be_able_to(:create, User)
		end

	end

	context 'Project collaborators' do

		before(:each) do
			user_create
		end

		context 'with read rights' do
			before(:each) do
				@project = Factory(:project)
				@project.relations.create!(:object_id => @user.id, :object_type => 'User', :role => 'read')
				open_platform.relations.create!(:object_id => @user.id, :object_type => 'User', :role => 'read')
			end

			it 'should be able to read project' do
				@ability.should be_able_to(:read, @project)
			end

			it 'should be able to read project' do
				@ability.should be_able_to(:read, open_platform)
			end
		end
		
		context 'with write rights' do
		end

		context 'with admin rights' do
			before(:each) do
				@project = Factory(:project, :owner => @user)
			end
		end

	end

end