shared_examples_for 'not destroy personal repository' do
  it 'should not be able to destroy personal repository' do
    delete :destroy, :id => @personal_repository.id
    response.should redirect_to(forbidden_path)
  end
end

shared_examples_for 'destroy personal repository' do
  it 'should be able to perform destroy action' do
    delete :destroy, :id => @repository.id
    response.should redirect_to(platform_path(@repository.platform.id))
  end
end
