ActiveAdmin.register_page 'Builders' do
  content do
    div class: 'index_as_table' do
      nodes = RpmBuildNode.all.to_a
      groups = nodes.group_by { |node| node.query_string.presence || '-' }
      groups.keys.sort.each do |key|
        description = if key != '-'
          parsed_key = Rack::Utils.parse_nested_query(key)
          parsed_key.delete('native_arches')
          tmp = parsed_key.keys.map do |prop|
            "#{prop.capitalize.gsub('_', ' ')}: #{parsed_key[prop].gsub(',', ' ')}"
          end + ["Total builders: #{groups[key].count}"]
          tmp.join(', ')
        else
          'Everything'
        end
        panel description do
          table_for groups[key], class: "index_table index" do
            column :host
            column :user_id do |b|
              u = User.find_by_id(b.user_id)
              u.present? ? link_to(u.uname, admin_user_path(u.id)) : 'Unknown'
            end
            column :system
            column :busy_workers
            column 'Last build ID' do |b|
              if b.last_build_id.present?
                link_to b.last_build_id, build_list_path(b.last_build_id)
              else
                'None'
              end
            end
          end
        end
      end
    end
  end
end
