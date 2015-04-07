shared_examples_for 'an admin controller' do

  it 'redirects to login when accessed unauthorised' do
    get :index
    expect(response).to redirect_to(new_user_session_path)
  end

  it 'raises a 404 for non-admin users' do
    user = User.first || FactoryGirl.create(:user)
    sign_in user
    get :index
    expect(response).to render_template(file: "#{Rails.root}/public/404.html")
  end

  it 'is successful for admin users' do
    user = FactoryGirl.create(:admin)
    sign_in user
    get :index
    expect(response).to be_success
  end

end
