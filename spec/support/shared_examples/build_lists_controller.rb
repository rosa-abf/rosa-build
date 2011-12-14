shared_examples_for 'show build list' do
  it 'should be able to perform show action' do
    get :show, @show_params
    response.should be_success
  end
end

shared_examples_for 'not show build list' do
  it 'should not be able to perform show action' do
    get :show, @show_params
    response.should redirect_to(forbidden_url)
  end
end
