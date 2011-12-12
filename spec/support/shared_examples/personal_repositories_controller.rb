shared_examples_for 'show personal repository' do
  it 'should be able to perform show action' do
    get :show, :id => @repository.id
    response.should render_template(:show)
  end
end

shared_examples_for 'add project to personal repository' do
  it 'should be able to perform add_project action' do
    get :add_project, :id => @repository.id
    response.should render_template(:projects_list)
  end
end

shared_examples_for 'add project personal repository with project_id param' do
  it 'should be able to perform add_project action with project_id param' do
    get :add_project, :id => @repository.id, :project_id => @project.id
    response.should redirect_to(personal_repository_path(@repository))
  end
end

shared_examples_for 'remove project from personal repository' do
  it 'should be able to perform remove_project action' do
    get :remove_project, :id => @repository.id, :project_id => @project.id
    response.should redirect_to(personal_repository_path(@repository))
  end
end

shared_examples_for 'destroy personal repository' do
  it 'should be able to perform destroy action' do
    delete :destroy, :id => @repository.id
    response.should redirect_to(platform_path(@repository.platform.id))
  end
end

shared_examples_for 'not destroy personal repository' do
  it 'should not be able to destroy personal repository' do
    delete :destroy, :id => @personal_repository.id
    response.should redirect_to(forbidden_path)
  end
end

shared_examples_for 'settings personal repository' do
  it 'should be able to perform settings action' do 
    get :settings, :id => @repository.id 
    response.should render_template(:settings)
  end
end

shared_examples_for 'change visibility' do
  it 'should be able to perform change_visibility action' do
    get :change_visibility, :id => @repository.id
    response.should redirect_to(settings_personal_repository_path(@repository))
  end

  it 'should change visibility of repository' do
    get :change_visibility, :id => @repository.id
    @repository.platform.reload.visibility.should == 'open'
  end
end
