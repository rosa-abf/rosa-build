shared_examples_for 'be_able_to_perform_index_action' do
  it 'should be able to perform index action' do
    get :index
    response.should render_template(:index)
  end
end

shared_examples_for 'be_able_to_perform_update_action' do
  it 'should be able to perform update action' do
    put :update, {:project_id => @project.id}.merge(@update_params)
    response.should redirect_to(project_path(@project))
  end
end

shared_examples_for 'update_collaborator_relation' do
  it 'should update collaborator relation' do
    @another_user.relations.exists? :target_id => @project.id, :target_type => 'Project', :role => 'read'
  end
end

shared_examples_for 'be_able_to_fork_project' do
  it 'should be able to fork project' do
    post :fork, :id => @project.id
    response.should redirect_to(project_path(Project.last))
  end
end

shared_examples_for 'be_able_to_perform_build_action' do
  it 'should be able to perform build action' do
    get :build, :id => @project.id
    response.should render_template(:build)
  end
end

shared_examples_for 'be_able_to_perform_process_build_action' do
  it 'should be able to perform process_build action' do
    post :process_build, {:id => @project.id}.merge(@process_build_params)
    response.should redirect_to(project_path(@project))
  end
end
