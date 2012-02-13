# -*- encoding : utf-8 -*-
module GitHelper

  def render_path
    # TODO: Looks ugly, rewrite with clear mind.
    if @path.present?
      if @treeish == "master"
        res = "#{link_to @project.name, tree_path(@project)} / "
      else
        res = "#{link_to @project.name, tree_path(@project, @treeish)} / "
      end

      parts = @path.split("/")

      current_path = parts.first
      res += parts.length == 1 ? parts.first : link_to(parts.first, tree_path(@project, @treeish, current_path)) + " / "

      parts[1..-2].each do |part|
        current_path = File.join([current_path, part].compact)
        res += link_to(part, tree_path(@project, @treeish, current_path))
        res += " / "
      end

      res += parts.last if parts.length > 1
    else
      res = "#{link_to @project.name, tree_path(@project)} /"
    end

    res.encode_to_default.html_safe
  end

  def blob_file_path
    if @commit_hash.present? 
      blob_commit_path(@project, @commit_hash, @path)
    else
      blob_path(@project, @treeish, @path)
    end
  end

  def render_line_numbers(n)
    res = ""
    1.upto(n) {|i| res += "<span>#{i}</span>\n" }

    res
  end

  def render_blob(blob)
    res = ""
    blob.data.encode_to_default.split("\n").collect do |line|
      "<div>#{line.present? ? h(line) : "<br>"}</div>"
    end.join
  end

  def choose_render_way(blob)
    return :image if blob.mime_type.match(/image/)
    return :text  if blob.mime_type.match(/text|xml|json/)
    :binary
  end

  def force_encoding_to_site(string)
    string.dup.encode_to_default
  end

end
