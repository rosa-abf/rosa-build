shared_examples_for 'be_able_to_perform_index#repositories' do
  it 'should be able to perform index action' do
    get :index
    response.should render_template(:index)
  end
end

shared_examples_for 'be_able_to_perform_show#repositories' do
  it 'should be able to perform show action' do
    get :show, :id => @repository.id
    response.should render_template(:show)
  end
end

shared_examples_for 'be_able_to_perform_add_project#repositories' do
  it 'should be able to perform add_project action' do
    get :add_project, :id => @repository.id
    response.should render_template(:projects_list)
  end
end

shared_examples_for 'be_able_to_perform_add_project#repositories_with_project_id_param' do
  it 'should be able to perform add_project action with project_id param' do
    get :add_project, :id => @repository.id, :project_id => @project.id
    response.should redirect_to(repository_path(@repository))
  end
end

shared_examples_for 'add_project_to_repository' do
  it 'should be able to add project to repository' do
    get :add_project, :id => @repository.id, :project_id => @project.id
    @repository.projects.exists? :id => @project.id
  end
end

shared_examples_for 'be_able_to_perform_remove_project#repositories' do
  it 'should be able to perform remove_project action' do
    get :remove_project, :id => @repository.id, :project_id => @project.id
    response.should redirect_to(repository_path(@repository))
  end
end

shared_examples_for 'remove project from repository' do
  it 'should be able to remove project from repository' do
    get :remove_project, :id => @repository.id, :project_id => @project.id
    !@repository.projects.exists? :id => @project.id
  end
end

shared_examples_for 'be_able_to_perform_destroy#repositories' do
  it 'should be able to perform destroy action' do
    delete :destroy, :id => @repository.id
    response.should redirect_to(platform_path(@repository.platform.id))
  end
end

shared_examples_for 'change_repositories_count_after_destroy' do
  it 'should change objects count after destroy action' do
    lambda { delete :destroy, :id => @repository.id }.should change{ Repository.count }.by(-1)
  end
end
