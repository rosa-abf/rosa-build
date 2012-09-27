# -*- encoding : utf-8 -*-
module GitHelper

  def render_path
    # TODO: Looks ugly, rewrite with clear mind.
    if @path.present?
      if @treeish == @project.default_branch
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

  def branch_selector_options(project)
    p = params.dup
    p.delete(:path) if p[:path].present? # to root path
    p.merge!(:project_id => project.id, :treeish => project.default_branch).delete(:id) unless p[:treeish].present?
    current = url_for(p).split('?', 2).first

    res = []
    if params[:treeish].present? && !project.repo.branches_and_tags.map(&:name).include?(params[:treeish])
      res << [I18n.t('layout.git.repositories.commits'), [params[:treeish].truncate(20)]]
    end
    linking = Proc.new {|t| [t.name.truncate(20), url_for(p.merge :treeish => t.name).split('?', 2).first]}
    res << [I18n.t('layout.git.repositories.branches'), project.repo.branches.map(&linking)]
    res << [I18n.t('layout.git.repositories.tags'), project.repo.tags.map(&linking)]

    grouped_options_for_select(res, current)
  end

  def versions_for_group_select(project)
    [ ['Branches', project.repo.branches.map{|b| "latest_#{b.name}"}],
      ['Tags', project.repo.tags.map(&:name)] ]
  end

  def split_commits_by_date(commits)
    commits.sort{|x, y| y.authored_date <=> x.authored_date}.inject({}) do |h, commit|
      dt = commit.authored_date
      h[dt.year] ||= {}
      h[dt.year][dt.month] ||= {}
      h[dt.year][dt.month][dt.day] ||= []
      h[dt.year][dt.month][dt.day] << commit
      h
    end
  end
end
