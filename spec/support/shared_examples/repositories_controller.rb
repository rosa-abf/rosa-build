shared_examples_for 'repository user with reader rights' do
  it 'should be able to perform index action' do
    get :index
    response.should render_template(:index)
  end

  it 'should be able to perform show action' do
    get :show, :id => @repository.id
    response.should render_template(:show)
  end
end

shared_examples_for 'repository user with owner rights' do
  it 'should be able to perform add_project action' do
    get :add_project, :id => @repository.id
    response.should render_template(:projects_list)
  end

  it 'should be able to perform add_project action with project_id param' do
    get :add_project, :id => @repository.id, :project_id => @project.id
    response.should redirect_to(repository_path(@repository))
  end

  it_should_behave_like 'repository user with add project rights'

  it 'should be able to perform remove_project action' do
    get :remove_project, :id => @repository.id, :project_id => @project.id
    response.should redirect_to(repository_path(@repository))
  end

  it_should_behave_like 'repository user with remove project rights'

  it 'should be able to perform destroy action' do
    delete :destroy, :id => @repository.id
    response.should redirect_to(platform_path(@repository.platform.id))
  end

  it 'should change objects count after destroy action' do
    lambda { delete :destroy, :id => @repository.id }.should change{ Repository.count }.by(-1)
  end

  it_should_behave_like 'repository user with reader rights'
end

shared_examples_for 'repository user with admin rights' do
  it_should_behave_like 'repository user with owner rights'
  it_should_behave_like 'destroy personal repository'
end

shared_examples_for 'repository user with add project rights' do
  it 'should be able to add project to repository' do
    get :add_project, :id => @repository.id, :project_id => @project.id
    @repository.projects.exists? :id => @project.id
  end
end

shared_examples_for 'repository user with remove project rights' do
  it 'should be able to remove project from repository' do
    get :remove_project, :id => @repository.id, :project_id => @project.id
    !@repository.projects.exists? :id => @project.id
  end
end
