shared_examples_for 'able_to_perform_index_action' do
  it 'should be able to perform index action' do
    get :index
    response.should render_template(:index)
  end
end

shared_examples_for 'not_be_able_to_perform_create_action' do
  it 'should be able to perform create action' do
    post :create, @create_params
    response.should redirect_to(forbidden_path)
  end
end

shared_examples_for 'not_be_able_to_destroy_personal_platform' do
  it 'should be able to perform create action' do
    delete :destroy, :id => @personal_platform.id
    response.should redirect_to(forbidden_path)
  end
end

shared_examples_for 'change_objects_count_on_destroy_success' do
  it 'should change objects count on destroy success' do
    lambda { delete :destroy, :id => @platform.id }.should change{ Platform.count }.by(-1)
  end
end

shared_examples_for 'be_able_to_perform_destroy_action' do
  it 'should be able to perform destroy action' do
    delete :destroy, :id => @platform.id
    response.should redirect_to(root_path)
  end

end
