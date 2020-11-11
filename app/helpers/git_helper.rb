module GitHelper

  def submodule_url(node, treeish)
    # node.url(treeish) looks like:
    # - http://0.0.0.0:3000/abf/git@abf.rosalinux.ru:abf/rhel-scripts.git
    # - git://github.com/avokhmin/mdv-scripts.git
    # - empty string if ".gitmodules" does not exist
    url = node.url(treeish)
    return nil if url.blank?
    url.gsub!(/.git$/, '')
    if url =~ /^git:/
      url.gsub!(/^git/, 'http')
    elsif str = /git@.*:.*/.match(url)
      str   = str[0].gsub(/^git@/, '')
      domen = str.gsub(/:.*/, '')
      owner = str.gsub(/^#{domen}:/, '').gsub(/\/.*/, '')
      project = str.gsub(/.*\//, '')
      url = "http://#{domen}/#{owner}/#{project}"
    end
    url
  end

  def render_path
    # TODO: Looks ugly, rewrite with clear mind.
    if @path.present?
      if @treeish == @project.resolve_default_branch
        res = "#{link_to @project.name, tree_path(@project)} / "
      else
        res = "#{link_to @project.name, tree_path(@project, @treeish)} / "
      end

      parts = @path.split("/")

      current_path = parts.first
      res << (parts.length == 1 ? parts.first : link_to(parts.first, tree_path(@project, @treeish, current_path)) + " / ")

      parts[1..-2].each do |part|
        current_path = File.join([current_path, part].compact)
        res << link_to(part, tree_path(@project, @treeish, current_path))
        res << " / "
      end

      res << parts.last if parts.length > 1
    else
      res = "#{link_to @project.name, tree_path(@project)} /"
    end

    res.html_safe
  end

  def render_line_numbers(n)
    res = ""
    1.upto(n){ |i| res << "<span id='L#{i}'><a href='#L#{i}'>#{i}</a></span><br/>" }

    res.html_safe
  end

  def iterate_path(path)
    tree = []
    path.split("\/").each do |name|
      if tree.last
        tree << [File.join(tree.try(:last).try(:first), name), name]
      else
        tree << [name, name]
      end
    end
    tree
  end

  def branch_selector_options(project)
    p, tag_enabled = params.dup, !(controller_name == 'trees' && action_name == 'branches')
    p.delete(:path) if p[:path].present? # to root path
    p.merge!(project_id: project.id, treeish: project.resolve_default_branch).delete(:id) unless p[:treeish].present?
    current = url_for(p).split('?', 2).first

    res = []
    if params[:treeish].present? && !project.repo.branches_and_tags.map(&:name).include?(params[:treeish])
      res << [I18n.t('layout.git.repositories.commits'), [params[:treeish].truncate(20)]]
    end
    linking = Proc.new {|name| [name.truncate(20), url_for(p.merge treeish: name).split('?', 2).first]}
    res << [I18n.t('layout.git.repositories.branches'), project.repo.branches.map(&:name).sort.map(&linking)]
    if tag_enabled
      res << [I18n.t('layout.git.repositories.tags'), project.repo.tags.map(&:name).sort.map(&linking)]
    else
      res << [I18n.t('layout.git.repositories.tags'), project.repo.tags.map(&:name).sort.map {|name| [name.truncate(20), {disabled: true}]}]
    end
    grouped_options_for_select(res, current)
  end

  def versions_for_group_select(project)
    return [] unless project
    [
      [I18n.t('layout.git.repositories.branches'), project.repo.branches.map(&:name).sort],
      [I18n.t('layout.git.repositories.tags'), project.repo.tags.map(&:name).sort]
    ]
  end

  def split_commits_by_date(commits)
    commits.inject({}) do |h, commit|
      dt = commit.committed_date
      h[dt.year] ||= {}
      h[dt.year][dt.month] ||= {}
      h[dt.year][dt.month][dt.day] ||= []
      h[dt.year][dt.month][dt.day] << commit
      h
    end
  end

  def blob_highlight(blob, path)
    return if blob.nil? || blob.size == 0
    rugged = blob.repo.rugged
    lazy = Linguist::LazyBlob.new(rugged, blob.id, path, blob.mode)
    language = lazy.language
    lexer = nil
    if language
      lexer = Pygments::Lexer.find_by_name(language.name)
      if !lexer
        language.aliases.each do |al|
          lexer = Pygments::Lexer.find_by_alias(al)
          break if lexer
        end
      end
      lexer = Pygments::Lexer.find('spec') if language.name == 'RPM Spec'
    end
    lexer = Pygments::Lexer.find('Text') if !lexer
    result = lexer.highlight rugged.lookup(blob.id).text, highlight_options
    result.present? ? result.html_safe : text
  rescue => e
    "<pre>#{blob.data}</pre>".html_safe
  end

  def blame_highlight(blob, path, text)
    return if blob.nil? || text.blank?
    rugged = blob.repo.rugged
    lazy = Linguist::LazyBlob.new(rugged, blob.id, path, blob.mode)
    language = lazy.language
    lexer = nil
    if language
      lexer = Pygments::Lexer.find_by_name(language.name)
      if !lexer
        language.aliases.each do |al|
          lexer = Pygments::Lexer.find_by_alias(al)
          break if lexer
        end
      end
      lexer = Pygments::Lexer.find('spec') if language.name == 'RPM Spec'
    end
    lexer = Pygments::Lexer.find('Text') if !lexer
    result = lexer.highlight(text)
    result.present? ? result.html_safe : text
  rescue => e
    puts e
    "<pre>#{text}</pre>".html_safe
  end

  protected

  def highlight_options
    @highlight ||= { options: { linenos: true, lineanchors: 'lc', linespans: 'ln', anchorlinenos: true }}
  end
end
