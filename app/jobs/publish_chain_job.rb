class PublishChainJob
  @queue = :middle

  def self.perform(build_list_id, user_id, testing = false)
    build_list = BuildList.find_by(id: build_list_id)
    return unless build_list
    return unless (testing && build_list.can_publish_chain_into_testing?) || (!testing && build_list.can_publish_chain?)

    user = User.find_by(id: user_id)
    return unless user

    if build_list.chain_build
      new_publish(build_list, user, testing)
    else
      old_publish(build_list, user, testing)
    end
  end

  def self.old_publish(build_list, user, testing)
    return unless build_list.top_of_chain?

    queue = [build_list.id]
    loop do
      bl_id = queue.pop
      break unless bl_id
      bl = BuildList.find(bl_id)
      bl.publisher = user
      if testing
        bl.publish_into_testing
      else
        bl.now_publish
      end
      queue += bl.extra_build_lists
    end
  end

  def self.new_publish(build_list, user, testing)
    build_list.chain_build.build_lists.find_each do |bl|
      bl.publisher = user
      if testing
        bl.publish_into_testing
      else
        bl.now_publish
      end
    end
  end
end