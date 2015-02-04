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
    response.should be_success #redirect_to(@return_path+"#comment#{Comment.last.id}")
  end

  it 'should create comment in the database' do
    lambda{ post :create, @create_params }.should change{ Comment.count }.by(1)
  end
end
shared_examples_for 'user with update own comment ability' do
  it 'should be able to perform update action' do
    put :update, {id: @own_comment.id}.merge(@update_params)
    response.status.should == 200
  end

  it 'should update subscribe body' do
    put :update, {id: @own_comment.id}.merge(@update_params)
    @own_comment.reload.body.should == 'updated'
  end
end
shared_examples_for 'user with update stranger comment ability' do
  it 'should be able to perform update action' do
    put :update, {id: @comment.id}.merge(@update_params)
    response.status.should == 200
  end

  it 'should update comment body' do
    put :update, {id: @comment.id}.merge(@update_params)
    @comment.reload.body.should == 'updated'
  end
end
shared_examples_for 'user without update stranger comment ability' do
  it 'should not be able to perform update action' do
    put :update, {id: @comment.id}.merge(@update_params)
    response.should redirect_to(forbidden_path)
  end

  it 'should not update comment body' do
    put :update, {id: @comment.id}.merge(@update_params)
    @comment.reload.body.should_not == 'updated'
  end
end
shared_examples_for 'user with destroy comment ability' do
  it 'should be able to perform destroy action' do
    delete :destroy, {id: @comment.id}.merge(@path)
    response.should be_success #redirect_to(@return_path)
  end

  it 'should delete comment from database' do
    lambda{ delete :destroy, {id: @comment.id}.merge(@path)}.should change{ Comment.count }.by(-1)
  end
end
shared_examples_for 'user without destroy comment ability' do
  it 'should not be able to perform destroy action' do
    delete :destroy, {id: @comment.id}.merge(@path)
    response.should redirect_to(forbidden_path)
  end

  it 'should not delete comment from database' do
    lambda{ delete :destroy, {id: @comment.id}.merge(@path)}.should change{ Issue.count }.by(0)
  end
end
