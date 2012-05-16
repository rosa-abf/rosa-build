# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Projects::Git::TreesController do

  def fill_project
    %x(cp -Rf #{Rails.root}/spec/tests.git/* #{@project.git_repository.path}) # maybe FIXME ?
  end

  before(:each) do
    stub_rsync_methods

    @project = FactoryGirl.create(:project)
    @another_user = FactoryGirl.create(:user)
    @params = {:owner_name => @project.owner.uname, :project_name => @project.name}
  end

  context 'for guest' do
    if APP_CONFIG['anonymous_access']
      it 'should be able to perform archive action with anonymous acccess' do
        fill_project
        get :archive, @params.merge(:format => 'tar')
        response.should be_success
      end
    else
      it 'should not be able to perform archive action without anonymous acccess' do
        fill_project
        get :archive, @params.merge(:format => 'tar')
        response.code.should == '401'
      end
    end
  end

  context 'for other user' do
    it 'should not be able to archive empty project' do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      expect { get :archive, @params.merge(:format => 'tar') }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should not be able to injection code with format' do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      fill_project
      expect { get :archive, @params.merge(:format => "tar master > /dev/null; echo 'I am hacker!';\#") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should not be able to injection code with treeish' do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      fill_project
      expect { get :archive, @params.merge(:treeish => "master > /dev/null; echo 'I am hacker!';\#") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should be able to perform archive action' do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      fill_project
      get :archive, @params.merge(:format => 'tar')
      response.should be_success
    end
  end
end
