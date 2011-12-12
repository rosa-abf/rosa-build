shared_examples_for 'show collaborators list' do
  it 'should be able to perform index action' do
    get :index, :project_id => @project.id
    response.should redirect_to(edit_project_collaborators_path(@project))
  end
end

shared_examples_for 'update collaborators' do
  it 'should be able to perform update action' do
    post :update, {:project_id => @project.id}.merge(@update_params)
    response.should redirect_to(project_path(@project))
  end
end

shared_examples_for 'update collaborator relation' do
  it 'should update collaborator relation' do
    @another_user.relations.exists? :target_id => @project.id, :target_type => 'Project', :role => 'read'
  end
end

shared_examples_for 'not show collaborators list' do
  it 'should be able to perform index action' do
    get :index, :project_id => @project.id
    response.should redirect_to(edit_project_collaborators_path(@project))
  end
end

shared_examples_for 'not update collaborators' do
  it 'should be able to perform update action' do
    post :update, {:project_id => @project.id}.merge(@update_params)
    response.should redirect_to(project_path(@project))
  end
end

shared_examples_for 'not update collaborator relation' do
  it 'should set flash notice on update success' do
    !@another_user.relations.exists? :target_id => @project.id, :target_type => 'Project', :role => 'read'
  end
end
