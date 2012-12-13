# -*- encoding : utf-8 -*-
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

shared_examples_for 'by default settings' do
  it 'should send an e-mail' do
    comment = create_comment(@stranger)
    ActionMailer::Base.deliveries.count.should == 1
    ActionMailer::Base.deliveries.last.to.include?(@user.email).should == true
  end
end
