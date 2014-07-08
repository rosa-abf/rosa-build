json.project do
  json.(@project, :id, :name)
  json.fullname '!!!!!!!!!' #@project.name_with_owner

  json.owner do
    json.(@project.owner, :id, :name, :uname)
  end
end

json.tree do
  json.array!@project.tree_info(@tree, @treeish, @path).each do |node, node_path, commit|
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

json.tree_breadcrumb do
  if @path.present?
    paths = File.split(@path)
    if paths.size > 1 && paths.first != '.'
      json.elements do
        json.array! paths.first.split(File::SEPARATOR).each do |a, name|
          if name != '.' && name != '..'
            path = File.join(a, name)
            path = path[1..-1] if path[0] == File::SEPARATOR
            if path.length > 1
              json.name path
              json.path name
            end
          end
        end
      end
      json.last paths.last
    end
  end
end

json.path @path
json.root_path @path.present? ? File.join([@path, ".."].compact) : nil
