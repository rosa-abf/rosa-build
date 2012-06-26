# -*- encoding : utf-8 -*-
shared_examples_for 'projects user with reader rights' do
  include_examples 'user with rights to view projects' # nested shared_examples_for dont work

  it 'should be able to fork project' do
    post :fork, :owner_name => @project.owner.uname, :project_name => @project.name
    response.should redirect_to(project_path(Project.last))
  end

end

shared_examples_for 'projects user with admin rights' do
  it 'should be able to perform update action' do
    put :update, {:owner_name => @project.owner.uname, :project_name => @project.name}.merge(@update_params)
    response.should redirect_to(project_path(@project))
  end
end

shared_examples_for 'user with rights to view projects' do
  it 'should be able to perform index action' do
    get :index
    response.should render_template(:index)
  end
end

shared_examples_for 'user without update rights' do
  it 'should not be able to edit project' do
    description = @project.description
    put :update, :project=>{:description =>"hack"}, :owner_name => @project.owner.uname, :project_name => @project.name
    Project.find(@project.id).description.should == description
    response.should redirect_to(forbidden_path)
  end

  it 'should not be able to edit project sections' do
    has_wiki, has_issues = @project.has_wiki, @project.has_issues
    post :sections, :project =>{:has_wiki => !has_wiki, :has_issues => !has_issues}, :owner_name => @project.owner.uname, :project_name => @project.name
    project = Project.find(@project.id)
    project.has_wiki.should == has_wiki
    project.has_issues.should == has_issues
    response.should redirect_to(forbidden_path)
  end
end
