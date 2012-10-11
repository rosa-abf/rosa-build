# -*- encoding : utf-8 -*-
module DiffHelper
  def render_diff_stats(stats)
    path = @pull.id ? polymorphic_path([@project, @pull]) : ''
    res = ["<table class='commit_stats'>"]
    stats.each_with_index do |stat, ind|
      res << "<tr>"
      res << "<td>#{link_to stat.filename.rtruncate(120), "#{path}#diff-#{ind}"}</td>"
      res << "<td class='diffstat'>"
      res << I18n.t("layout.projects.inline_changes_count", :count => stat.additions + stat.deletions).strip +
             " (" +
             I18n.t("layout.projects.inline_additions_count", :count => stat.additions).strip +
             ", " +
             I18n.t("layout.projects.inline_deletions_count", :count => stat.deletions).strip +
             ")"
      res << "</td>"
    end
    res << "</table>"

    res.join("\n").html_safe.default_encoding!
  end

  #include Git::Diff::InlineCallback
  def render_diff(diff, diff_counter, comments, diffpath = nil)
    if diff.respond_to?(:diff)
      filepath = diff.a_path
      diff = diff.diff
      in_discussion = false
      comments = comments.select{|c| c.data.try('[]', :path) == filepath}
    else
      filepath = diffpath
      in_discussion = true
    end

    diff_display ||= Diff::Display::Unified.new(diff)
    url = if @pull
             @pull.id ? polymorphic_path([@project, @pull]) : ''
           elsif @commit
             commit_path @project, @commit
           end
    prepare(url, diff_counter, filepath, comments, in_discussion)

    res = "<table class='diff inline' cellspacing='0' cellpadding='0'>"
    res += "<tbody>"
    res += renderer diff_display.data #diff_display.render(Git::Diff::InlineCallback.new comments, path)
    res += tr_line_comments(comments) if in_discussion
    res += "</tbody>"
    res += "</table>"
    res.html_safe
  end

  ########################################################
  # FIXME: Just to dev, remove to lib
  ########################################################
  def prepare(url, diff_counter, filepath, comments, in_discussion)
    @num_line, @url, @diff_counter, @in_discussion = -1, url, diff_counter, in_discussion
    @filepath, @line_comments = filepath, comments
  end

  def headerline(line)
    set_line_number
    "<tr class='header'>
      <td class='line_numbers'>...</td>
      <td class='line_numbers'>...</td>
      <td class='header'>#{line}</td>
    </tr>"
  end

  def addline(line)
    set_line_number
    "<tr class='changes'>
      <td class='line_numbers'></td>
      #{td_line_link "diff-F#{@diff_counter}R#{line.new_number}", line.new_number}
      <td class='code ins'>
        #{line_comment}
        <pre>#{render_line(line)}</pre>
      </td>
     </tr>
     #{render_line_comments}"
  end

  def remline(line)
    set_line_number
    "<tr class='changes'>
      #{td_line_link "diff-F#{@diff_counter}L#{line.old_number}", line.old_number}
      <td class='line_numbers'></td>
      <td class='code del'>
        #{line_comment}
        <pre>#{render_line(line)}</pre>
      </td>
    </tr>
    #{render_line_comments}"
  end

  def modline(line)
    set_line_number
    "<tr clas='chanes line'>
      #{td_line_link "diff-F#{@diff_counter}L#{line.old_number}", line.old_number}
      #{td_line_link "diff-F#{@diff_counter}R#{line.new_number}", line.new_number}
      <td class='code unchanged modline'>
        #{line_comment}
        <pre>#{render_line(line)}</pre>
      </td>
    </tr>
    #{render_line_comments}"
  end

  def unmodline(line)
    set_line_number
    "<tr class='changes unmodline'>
      #{td_line_link "diff-F#{@diff_counter}L#{line.old_number}", line.old_number}
      #{td_line_link "diff-F#{@diff_counter}R#{line.new_number}", line.new_number}
      <td class='code unchanged unmodline'>
        #{line_comment}
        <pre>#{render_line(line)}</pre>
      </td>
    </tr>
    #{render_line_comments}"
  end

  def sepline(line)
    "<tr class='changes hunk-sep'>
      <td class='line_numbers line_num_cut'>&hellip;</td>
      <td class='line_numbers line_num_cut'>&hellip;</td>
      <td class='code cut-line'></td>
    </tr>"
  end

  def nonewlineline(line)
    set_line_number
    "<tr class='changes'>
      #{td_line_link "diff-F#{@diff_counter}L#{line.old_number}", line.old_number}
      #{td_line_link "diff-F#{@diff_counter}R#{line.new_number}", line.new_number}
      <td class='code modline unmodline'>
        #{line_comment}
        <pre>#{render_line(line)}</pre>
      </td>
    </tr>
    #{render_line_comments}"
  end

  def before_headerblock(block)
  end

  def after_headerblock(block)
  end

  def before_unmodblock(block)
  end

  def before_modblock(block)
  end

  def before_remblock(block)
  end

  def before_addblock(block)
  end

  def before_sepblock(block)
  end

  def before_nonewlineblock(block)
  end

  def after_unmodblock(block)
  end

  def after_modblock(block)
  end

  def after_remblock(block)
  end

  def after_addblock(block)
  end

  def after_sepblock(block)
  end

  def after_nonewlineblock(block)
  end

  def new_line
    ""
  end

  def renderer(data)
    result = []
    data.each do |block|
      result << send("before_" + classify(block), block)
      result << block.map { |line| send(classify(line), line) }
      result << send("after_" + classify(block), block)
    end
    result.compact.join(new_line)
  end

  protected

  def classify(object)
    object.class.name[/\w+$/].downcase
  end

  def escape(str)
    str.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&#34;')
  end

  def render_line(line)
    res = '<span class="diff-content">'
    if line.inline_changes?
      prefix, changed, postfix = line.segments.map{|segment| escape(segment) }
      res += "#{prefix}<span class='idiff'>#{changed}</span>#{postfix}"
    else
      res += escape(line)
    end
    res += '</span>'

    res
  end

  def set_line_number
    @num_line = @num_line.succ
  end

  def line_comment
    link_to image_tag('line_comment.png', :alt => t('layout.comments.new_header')), new_comment_path, :class => 'add_line-comment'
  end

  def render_line_comments
    unless @in_discussion
      comments = @line_comments.select do |c|
        c.data.try('[]', :line) == @num_line.to_s && c.actual_inline_comment?(@diff)
      end
      tr_line_comments(comments) if comments.count > 0
    end
  end

  def td_line_link id, num
    "<td class='line_numbers' id='#{id}'><a href='#{@url}##{id}'>#{num}</a></td>"
  end

  def tr_line_comments comments
    "<tr class='inline-comments'>
      <td class='line_numbers' colspan='2'>#{comments.count}</td>
      <td>
        #{render("projects/comments/line_list", :list => comments, :project => @project, :commentable => @commentable)}
        #{link_to t('layout.comments.new_inline'), new_comment_path, :class => 'new_inline_comment button'}
      </td>
     </tr>"
  end

  def new_comment_path
    if @commentable.class == Issue
      project_new_line_pull_comment_path(@project, @commentable, :path => @filepath, :line => @num_line)
    elsif @commentable.class == Grit::Commit
      new_line_commit_comment_path(@project, @commentable, :path => @filepath, :line => @num_line)
    end
  end
end
