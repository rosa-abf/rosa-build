ActiveAdmin.register_page 'Builders' do
  content do
    div class: 'index_as_table' do
      table_for RpmBuildNode.all.to_a.select { |b| b.get_ttl > 0 }, class: "index_table index" do
        column :id
        column :user_id do |b|
          User.find(b.user_id) rescue 'User not found.'
        end
        column :system
        column :hostname
        column :busy_workers
        column :query_string
        column 'Last build ID' do |b|
          if b.last_build_id
            link_to b.last_build_id, build_list_path(b.last_build_id)
          else
            'None'
          end
        end
      end
    end
  end
end
