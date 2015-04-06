shared_examples_for 'user with create comment ability (for model)' do
  it 'should create comment' do
    @ability.should be_able_to(:create, @comment)
  end
end
shared_examples_for 'user with update own comment ability (for model)' do
  it 'should update comment' do
    @ability.should be_able_to(:update, @comment)
  end
end
shared_examples_for 'user with update stranger comment ability (for model)' do
  it 'should update stranger comment' do
    @ability.should be_able_to(:update, @stranger_comment)
  end
end
shared_examples_for 'user with destroy comment ability (for model)' do
  it 'should destroy own comment' do
    @ability.should be_able_to(:destroy, @comment)
  end
end
shared_examples_for 'user with destroy stranger comment ability (for model)' do
  it 'should destroy stranger comment' do
    @ability.should be_able_to(:destroy, @stranger_comment)
  end
end

shared_examples_for 'user without update stranger comment ability (for model)' do
  it 'should not update stranger comment' do
    @ability.should_not be_able_to(:update, @stranger_comment)
  end
end
shared_examples_for 'user without destroy stranger comment ability (for model)' do
  it 'should not destroy stranger comment' do
    @ability.should_not be_able_to(:destroy, @stranger_comment)
  end
end

shared_examples_for 'user with create comment ability' do
  it 'should be able to perform create action' do
    post :create, @create_params
    expect(response).to be_success #redirect_to(@return_path+"#comment#{Comment.last.id}")
  end

  it 'should create comment in the database' do
    expect do
      post :create, @create_params
    end.to change(Comment, :count).by(1)
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
    delete :destroy, {id: @comment.id}.merge(@path)
    expect(response).to be_success #redirect_to(@return_path)
  end

  it 'should delete comment from database' do
    expect do
      delete :destroy, {id: @comment.id}.merge(@path)
    end.to change(Comment, :count).by(-1)
  end
end
shared_examples_for 'user without destroy comment ability' do
  it 'should not be able to perform destroy action' do
    delete :destroy, {id: @comment.id}.merge(@path)
    expect(response).to redirect_to(forbidden_path)
  end

  it 'should not delete comment from database' do
    expect do
      delete :destroy, {id: @comment.id}.merge(@path)
    end.to_not change(Issue, :count)
  end
end
