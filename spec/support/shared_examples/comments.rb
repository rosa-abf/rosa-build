shared_examples_for 'user with create comment ability' do
  it 'should be able to perform create action' do
    post :create, @create_params
    expect(response).to be_success #redirect_to(@return_path+"#comment#{Comment.last.id}")
  end

  it 'should create comment in the database' do
    expect {
      post :create, @create_params
    }.to change(Comment, :count).by(1)
  end
end
shared_examples_for 'user with update own comment ability' do
  it 'should be able to perform update action' do
    put :update, {id: @own_comment.id}.merge(@update_params)
    expect(response).to be_success
  end

  it 'should update subscribe body' do
    put :update, {id: @own_comment.id}.merge(@update_params)
    expect(@own_comment.reload.body).to eq 'updated'
  end
end
shared_examples_for 'user with update stranger comment ability' do
  it 'should be able to perform update action' do
    put :update, {id: @comment.id}.merge(@update_params)
    expect(response).to be_success
  end

  it 'should update comment body' do
    put :update, {id: @comment.id}.merge(@update_params)
    expect(@comment.reload.body).to eq 'updated'
  end
end
shared_examples_for 'user without update stranger comment ability' do
  it 'should not be able to perform update action' do
    put :update, {id: @comment.id}.merge(@update_params)
    expect(response).to redirect_to(forbidden_path)
  end

  it 'should not update comment body' do
    put :update, {id: @comment.id}.merge(@update_params)
    expect(@comment.reload.body).to_not eq 'updated'
  end
end
shared_examples_for 'user with destroy comment ability' do
  it 'should be able to perform destroy action' do
    delete :destroy, {id: @comment.id, format: :json}.merge(@path)
    expect(response).to be_success #redirect_to(@return_path)
  end

  it 'should delete comment from database' do
    expect do
      delete :destroy, {id: @comment.id, format: :json}.merge(@path)
    end.to change(Comment, :count).by(-1)
  end
end
shared_examples_for 'user without destroy comment ability' do
  it 'should not be able to perform destroy action' do
    delete :destroy, {id: @comment.id, format: :json}.merge(@path)
    expect(response).to redirect_to(forbidden_path)
  end

  it 'should not delete comment from database' do
    expect do
      delete :destroy, {id: @comment.id, format: :json}.merge(@path)
    end.to_not change(Issue, :count)
  end
end
