if params[:info] == 'true'
  json.project do
    json.(@project, :id, :name)
    json.fullname @project.name_with_owner

    json.owner do
      json.(@project.owner, :id, :name, :uname)
    end
  end
else

  page = params[:page].to_i

  json.tree do
    json.array!@project.tree_info(@tree, @treeish, @path, page).each do |node, node_path, commit|
      if node.is_a? Grit::Submodule
        url = submodule_url(node, @treeish)
        json.submodule do
          json.url      url
          json.name     node.name
          json.tree_url "#{url}/tree/#{node.id}"
          json.id       node.id[0..6]
        end
      else

        json.node do
          options = [@project, @treeish, node_path]
          if node.is_a?(Grit::Tree)
            json.class_name 'fa-folder'
            json.url        tree_path *options
          else
            json.class_name 'fa-file-text-o'
            json.url        blob_path(*options)
          end
          json.name         node.name
          json.path         node_path
        end
      end
      if commit
        json.commit do
          json.committed_date commit.committed_date
          json.short_message  commit.short_message
          json.url            commit_path(@project, commit)
        end
      end
    end
  end

  json.breadcrumb do
    if @path.present?
      paths = File.split(@path)
      if paths.size > 1 and paths.first != '.'
        json.paths do
          json.array! iterate_path(paths.first).each do |el|
            json.path el.first
            json.name el.last
          end
        end
      end
      json.last paths.last
    end
  end

  json.path @path
  json.root_path @path.present? ? File.join([@path, ".."].compact) : nil
  params[:page].to_i
  json.next_page page.next if @tree.contents.count >= Project::CONTENT_LIMIT*(page+1)
end
