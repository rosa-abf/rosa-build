module DiffHelper
  def render_diff_stats(stats)
    path = @pull.try(:id) ? polymorphic_path([@project, @pull]) : ''
    res = ["<table class='commit_stats'>"]
    stats.each_with_index do |stat, ind|
      res << "<tr>"
      res << "<td>#{link_to stat.filename.rtruncate(120), "#{path}#diff-#{ind}"}</td>"
      res << "<td class='diffstat'>"
      res << I18n.t("layout.projects.inline_changes_count", count: stat.additions + stat.deletions).strip +
             " (" +
             I18n.t("layout.projects.inline_additions_count", count: stat.additions).strip +
             ", " +
             I18n.t("layout.projects.inline_deletions_count", count: stat.deletions).strip +
             ")"
      res << "</td>"
    end
    res << "</table>"

    res.join("\n").html_safe
  end

  #include Git::Diff::InlineCallback
  def render_diff(diff, args = {})#diff_counter, comments, opts = nil diffpath = nil)
    if diff.respond_to?(:diff)
      diff, filepath, in_discussion = diff.diff, diff.a_path, false
      comments = (args[:comments] || []).select{|c| c.data.try('[]', :path) == filepath}
    else
      filepath, in_discussion, comments = args[:diffpath], true, args[:comments]
    end

    diff_display ||= Diff::Display::Unified.new(diff)
    url = if @pull
             @pull.id ? polymorphic_path([@project, @pull]) : ''
           elsif @commit
             commit_path @project, @commit
           end
    prepare(args.merge({filepath: filepath, comments: comments, in_discussion: in_discussion}))

    res = '<table class="table diff inline" cellspacing="0" cellpadding="0">'
    res << '<tbody>'
    res << renderer(diff_display.data) #diff_display.render(Git::Diff::InlineCallback.new comments, path)
    res << tr_line_comments(comments) if in_discussion
    res << '</tbody>'
    res << '</table>'
    res.html_safe
  end

  ########################################################
  # FIXME: Just to dev, remove to lib. Really need it?
  ########################################################
  def prepare(args)
    @url, @diff_counter, @in_discussion = args[:url], args[:diff_counter], args[:in_discussion]
    @filepath, @line_comments = args[:filepath], args[:comments]
    @diff_prefix = args[:diff_prefix] || 'diff'
    @add_reply_id, @num_line = if @in_discussion
        [@line_comments[0].id, @line_comments[0].data[:line].to_i - @line_comments[0].data[:strings].lines.count.to_i-1]
      else
        [nil, -1]
      end

    @no_commit_comment = true if params[:controller] == 'projects/wiki' || (params[:action] == 'diff')
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
      #{td_line_link "#{@diff_prefix}-F#{@diff_counter}R#{line.new_number}", line.new_number}
      <td class='code ins'>
        #{line_comment_icon}
        <pre ng-non-bindable>#{render_line(line)}</pre>
      </td>
     </tr>
     #{render_line_comments}"
  end

  def remline(line)
    set_line_number
    "<tr class='changes'>
      #{td_line_link "#{@diff_prefix}-F#{@diff_counter}L#{line.old_number}", line.old_number}
      <td class='line_numbers'></td>
      <td class='code del'>
        #{line_comment_icon}
        <pre ng-non-bindable>#{render_line(line)}</pre>
      </td>
    </tr>
    #{render_line_comments}"
  end

  def modline(line)
    set_line_number
    "<tr clas='changes line'>
      #{td_line_link "#{@diff_prefix}-F#{@diff_counter}L#{line.old_number}", line.old_number}
      #{td_line_link "#{@diff_prefix}-F#{@diff_counter}R#{line.new_number}", line.new_number}
      <td class='code unchanged modline'>
        #{line_comment_icon}
        <pre ng-non-bindable>#{render_line(line)}</pre>
      </td>
    </tr>
    #{render_line_comments}"
  end

  def unmodline(line)
    set_line_number
    "<tr class='changes unmodline'>
      #{td_line_link "#{@diff_prefix}-F#{@diff_counter}L#{line.old_number}", line.old_number}
      #{td_line_link "#{@diff_prefix}-F#{@diff_counter}R#{line.new_number}", line.new_number}
      <td class='code unchanged unmodline'>
        #{line_comment_icon}
        <pre ng-non-bindable>#{render_line(line)}</pre>
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
    "<tr class='changes' ng-non-bindable>
      #{td_line_link "#{@diff_prefix}-F#{@diff_counter}L#{line.old_number}", line.old_number}
      #{td_line_link "#{@diff_prefix}-F#{@diff_counter}R#{line.new_number}", line.new_number}
      <td class='code modline unmodline'>
        #{line_comment_icon}
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
      res << "#{prefix}<span class='idiff'>#{changed}</span>#{postfix}"
    else
      res << escape(line)
    end
    res << '</span>'

    res
  end

  def set_line_number
    @num_line = @num_line.succ
  end

  def line_comment_icon
    return if @no_commit_comment || (@in_discussion && @add_reply_id && @line_comments[0].data[:line].to_i != @num_line)
    if current_user
      link_to image_tag('line_comment.png', alt: t('layout.comments.new_header')),
              '#new_inline_comment',
              class: 'add_line-comment',
              'ng-click' => "commentsCtrl.showInlineForm(#{new_inline_comment_params.to_json})"
    end
  end

  def render_line_comments
    unless @no_commit_comment || @in_discussion
      comments = @line_comments.select do |c|
        c.data.try('[]', :line) == @num_line.to_s && c.actual_inline_comment?
      end
      tr_line_comments(comments) if comments.count > 0
    end
  end

  def td_line_link id, num
    "<td class='line_numbers' id='#{id}'><a href='#{@url}##{id}'>#{num}</a></td>"
  end

  def tr_line_comments comments
    return if @no_commit_comment
    res="<tr class='line-comments'>
      <td class='line_numbers' colspan='2'>#{comments.count}</td>
      <td>"
      comments.each do |comment|
        res << "<div class='line-comment'>
          #{render 'projects/comments/comment', comment: comment, data: {project: @project, commentable: @commentable, add_anchor: 'inline', in_discussion: @in_discussion}}
         </div>"
      end
    if current_user
      res << link_to( t('layout.comments.new_inline'),
                      '#new_inline_comment',
                      class: 'btn btn-primary',
                      'ng-click' => "commentsCtrl.showInlineForm(#{new_inline_comment_params.to_json})",
                      'ng-hide'  => "commentsCtrl.hideInlineCommentButton(#{new_inline_comment_params.to_json})" )
    end
    res << "</td></tr>"
  end
  # def new_comment_path
  #   hash = {path: @filepath, line: @num_line}
  #   if @commentable.is_a? Issue
  #     project_new_line_pull_comment_path(@project, @commentable, hash.merge({in_reply: @add_reply_id}))
  #   elsif @commentable.is_a? Grit::Commit
  #     new_line_commit_comment_path(@project, @commentable, hash)
  #   end
  # end

  def new_inline_comment_params
    { path: @filepath, line: @num_line, in_reply: @add_reply_id }
  end

end
