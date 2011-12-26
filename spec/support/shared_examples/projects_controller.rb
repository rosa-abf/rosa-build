shared_examples_for 'projects user with reader rights' do
  it_should_behave_like 'user with rights to view projects'

  it 'should be able to fork project' do
    post :fork, :id => @project.id
    response.should redirect_to(project_path(Project.last))
  end
end

shared_examples_for 'projects user with writer rights' do
  it 'should be able to perform update action' do
    put :update, {:id => @project.id}.merge(@update_params)
    response.should redirect_to(project_path(@project))
  end
end

shared_examples_for 'user with rights to view projects' do
  it 'should be able to perform index action' do
    get :index
    response.should render_template(:index)
  end
end
