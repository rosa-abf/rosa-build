module CommitHelper
  MAX_FILES_WITHOUT_COLLAPSE = 25

  def render_commit_stats(options = {})
    stats         = options[:stats]
    diff          = options[:diff]
    repo          = options[:repo]
    commit        = options[:commit]
    parent_commit = commit.parents.try(:first)

    res = ["<ul class='list-group boffset0'>"]
    ind=0
    stats.files.each do |filename, adds, deletes, total|
      file_name = get_filename_in_diff(diff[ind], filename)
      file_status = t "layout.projects.diff.#{get_file_status_in_diff(diff[ind])}"
      res << "<li class='list-group-item'>"
        res << "<div class='row'>"
          res << "<div class='col-sm-8'>"
            res << "<a href='#diff-#{ind}' data-toggle='tooltip' data-placement='top' title='#{file_status}'>"
              res << "#{diff_file_icon(diff[ind])} #{h(file_name)}"
            res << "</a></div>"
          res << render_file_changes(diff: diff[ind], adds: adds, deletes: deletes, total: total,
                                     repo: repo, commit: commit, parent_commit: parent_commit, file_status: file_status)
        res << "</div"
      res << "</li>"
      ind +=1
    end
    res << "</ul>"

    wrap_commit_header_list(stats, res)
  end

  def wrap_commit_header_list(stats, list)
    is_stats_open = stats.files.count <= MAX_FILES_WITHOUT_COLLAPSE ? 'in' : ''
    res = ["<div class='panel-group' id='diff_header' role='tablist' aria-multiselectable='false'>"]
      res << "<div class='panel panel-default'>"
        res << "<div class='panel-heading' role='tab' id='heading'>"
          res << "<h4 class='panel-title'>"
            res << "<a data-toggle='collapse' data-parent='#diff_header' href='#collapseList' aria-expanded='true' aria-controls='collapseList'>"
            res << "<span class='fa fa-chevron-#{is_stats_open ? 'down' : 'up'}'></span>"
            res << " #{diff_commit_header_message(stats)}</a>"
          res << "</h4>"
        res << "</div>"
        res << "<div id='collapseList' class='panel-collapse collapse #{is_stats_open}' role='tabpanel' aria-labelledby='collapseList'>"
          res << "<div class='panel-body'>"
            res += list
          res << "</div>"
        res << "</div>"
      res << "</div>"
    res << "</div>"
    res.join("\n").html_safe
  end

  def diff_commit_header_message(stats)
    t("layout.projects.diff_show_header",
      files:     t("layout.projects.commit_files_count",     count: stats.files.size),
      additions: t("layout.projects.commit_additions_count", count: stats.additions),
      deletions: t("layout.projects.commit_deletions_count", count: stats.deletions))
  end

  def commit_date(date)
    I18n.localize(date, { format: "%d %B %Y" })
  end

  def short_hash_id(id)
    id[0..19]
  end

  def shortest_hash_id(id, size=10)
    id[0..size-1]
  end

  def commit_author_link(author)
    name = author.name
    email = author.email
    u = User.where(email: email).first
    u.present? ? link_to(name, user_path(u)) : mail_to(email, name)
  end

  def commits_pluralize(commits_count)
    Russian.p(commits_count, *commits_pluralization_arr)
  end

  def is_file_open_in_diff(blob, diff)
    return true if blob.binary? && blob.render_as == :image
    return true if diff.diff.blank? && diff.a_mode != diff.b_mode
    diff.diff.present? && diff.diff.split("\n").count <= DiffHelper::MAX_LINES_WITHOUT_COLLAPSE
  end

  def file_blob_in_diff(repo, commit_id, diff)
    tree = repo.tree(commit_id)
    diff.renamed_file ? (tree / diff.b_path) : (tree / (diff.a_path.presence || diff.b_path))
  end

  def get_commit_id_for_file(diff, commit, parent_commit)
    diff.deleted_file ? parent_commit.id : commit.id
  end

  def get_file_status_in_diff(diff)
    if diff.renamed_file
      :renamed_file
    elsif diff.new_file
      :new_file
    elsif diff.deleted_file
      :deleted_file
    else
      :changed_file
    end
  end

  def get_filename_in_diff(diff, filename)
    if diff.renamed_file
      "#{diff.a_path.rtruncate 50} => #{diff.b_path.rtruncate 50}"
    else
      filename.rtruncate(100)
    end
  end

  protected

  def commits_pluralization_arr
    pluralize ||=  t('layout.commits.pluralize').map {|base, title| title.to_s}
  end

  def render_file_changes(options = {})
    diff        = options[:diff]
    adds        = options[:adds]
    deletes     = options[:deletes]
    total       = options[:total]
    repo        = options[:repo]
    file_status = options[:file_status]
    commit_id   = get_commit_id_for_file(diff, options[:commit], options[:parent_commit])
    blob        = file_blob_in_diff(repo, commit_id, diff)

    res = ''
    res << "<div class='col-sm-3'>"
      res << "<div class='pull-right'>"
        if blob.binary?
          res << "<strong class='text-primary'>#{t 'layout.projects.diff.binary'} #{file_status}</strong>"
        elsif total > 0
          res << "<strong class='text-success'>+#{adds}</strong> <strong class='text-danger'>-#{deletes}</strong>"
        else # total == 0
          res << "<strong class='text-primary'>#{t 'layout.projects.diff.without_changes'}</strong>"
        end
      res << "</div>"
    res << "</div>"

    res << "<div class='col-sm-1'>"
      res << render_progress_bar(adds, deletes, total, blob)
    res << "</div>"

  end

  def render_progress_bar(adds, deletes, total, blob)
    res = ''
    pluses  = 0
    minuses = 0

    if total > 0
      pluses  = ((adds/(adds+deletes).to_f)*100).round
      minuses = 100 - pluses
    end

    title = if total >0
              t 'layout.projects.inline_changes_count', count: total
            elsif !blob.binary?
              t 'layout.projects.diff.without_changes'
            else
              'BIN'
            end

    res << "<div class='progress' style='margin-bottom: 0' data-toggle='tooltip' data-placement='top' title='#{title}'>"
      res << "<div class='progress-bar progress-bar-success' style='width: #{pluses}%'></div>"
      res << "<div class='progress-bar progress-bar-danger' style='width: #{minuses}%'></div>"
    res << "</div>"
    res
  end

  def diff_file_icon(diff)
    icon = case get_file_status_in_diff(diff)
           when :renamed_file
             'fa-caret-square-o-right text-info'
           when :new_file
             'fa-plus-square text-success'
           when :deleted_file
             'fa-minus-square text-danger'
           when :changed_file
             'fa-pencil-square text-primary'
           else
             'fa-exclamation-circle text-danger'
           end
    "<i class='fa #{icon}'></i>"
  end
end
