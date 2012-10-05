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
  def render_diff(diff, diff_counter)
    diff_display ||= Diff::Display::Unified.new(diff.diff)
    url = if @pull
             @pull.id ? polymorphic_path([@project, @pull]) : ''
           elsif @commit
             commit_path @project, @commit
           end
    prepare(diff, url, diff_counter)

    res = "<table class='diff inline' cellspacing='0' cellpadding='0'>"
    res += "<tbody>"
    res += renderer diff_display.data #diff_display.render(Git::Diff::InlineCallback.new comments, path)
    res += "</tbody>"
    res += "</table>"
    res.html_safe
  end

  ########################################################
  # FIXME: Just to dev, remove to lib
  ########################################################
  def prepare(diff, url, diff_counter)
    @diff, @num_line, @filepath, @url, @diff_counter = diff, -1, diff.a_path, url, diff_counter
    @line_comments = @comments.select{|c| c.data.try('[]', :path) == @filepath}
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
    path = if @commentable.class == Issue
             project_new_line_pull_comment_path(@project, @commentable, :path => @filepath, :line => @num_line)
           elsif @commentable.class == Grit::Commit
             new_line_commit_comment_path(@project, @commentable, :path => @filepath, :line => @num_line)
           end
    link_to image_tag('line_comment.png', :alt => t('layout.comments.new_header')), path, :class => 'add_line-comment'
  end

  def render_line_comments
    comments = @line_comments.select do |c|
      next false if c.data.try('[]', :line) != @num_line.to_s
      next true if c.commentable_type == 'Grit::Commit'
      #diff = Diff::Display::Unified.new(@diff.diff)
      res, ind = true, 0
      @diff.diff.each_line do |line|
        res = false if (@num_line-2..@num_line+2).include?(ind) && c.data.try('[]', "line#{ind-@num_line}") != line.chomp
        ind = ind + 1
      end
      res
    end
    "<tr>
      <td class='line_numbers line_comments' colspan='2'>#{comments.count}</td>
      <td>#{render("projects/comments/line_list", :list => comments, :project => @project, :commentable => @commentable)}</td>
     </tr>" if comments.count > 0
  end

  def td_line_link id, num
    "<td class='line_numbers' id='#{id}'><a href='#{@url}##{id}'>#{num}</a></td>"
  end
end
