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

    res.html_safe
  end

  def render_line_numbers(n)
    res = ""
    1.upto(n) {|i| res += "<span>#{i}</span><br/>" }

    res.html_safe
  end

  def render_blob(blob)
    blob.data.split("\n").collect do |line|
      content_tag :div, line.present? ? h(line) : tag(:br)
    end.join.html_safe
  end

  def choose_render_way(blob)
    case
    when blob.mime_type.match(/image/); :image
    when blob.binary?; :binary
    else
      @text = @blob.data.split("\n")
      :text
    end
  end

  def iterate_path(path, &block)
    path.split(File::SEPARATOR).inject('') do |a, e|
      if e != '.' and e != '..'
        a = File.join(a, e)
        a = a[1..-1] if a[0] == File::SEPARATOR
        block.call(a, e) if a.length > 1
      end
      a
    end
  end

  # TODO This is very dirty hack. Maybe need to be changed.
  def branch_selector_options(project)
    p = params.dup
    p.delete(:path) if p[:path].present? # to root path
    p.merge!(:project_id => project.id, :treeish => project.default_branch).delete(:id) unless p[:treeish].present?
    current = url_for(p).split('?', 2).first

    res = []
    res << [I18n.t('layout.git.repositories.commits'), [truncate(params[:treeish], :length => 20)]] unless (project.branches + project.tags).map(&:name).include?(params[:treeish] || project.default_branch)
    res << [I18n.t('layout.git.repositories.branches'), project.branches.map{|b| [truncate(b.name, :length => 20), url_for(p.merge :treeish => b.name).split('?', 2).first]}]
    res << [I18n.t('layout.git.repositories.tags'), project.tags.map{|t| [truncate(t.name, :length => 20), url_for(p.merge :treeish => t.name).split('?', 2).first]}]

    grouped_options_for_select(res, current)
  end

  def split_commits_by_date(commits)
    res = commits.sort{|x, y| y.authored_date <=> x.authored_date}.inject({}) do |h, commit|
      dt = commit.authored_date
      h[dt.year] ||= {}
      h[dt.year][dt.month] ||= {}
      h[dt.year][dt.month][dt.day] ||= []
      h[dt.year][dt.month][dt.day] << commit
      h
    end
    return res
  end

end
