shared_examples_for 'be_able_to_perform_index#groups' do
  it 'should be able to perform index action' do
    get :index
    response.should render_template(:index)
  end
end

shared_examples_for 'be_able_to_perform_update#groups' do
  it 'should be able to perform update action' do
    put :update, {:id => @group.id}.merge(@update_params)
    response.should redirect_to(group_path(@group))
  end
end


