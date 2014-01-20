shared_examples_for 'update_member_relation' do
  it 'should update member relation' do
    @another_user.relations.exists? :target_id => @group.id, :target_type => 'Group', :role => 'read'
  end
end

