module CommitHelper
  MAX_FILES_WITHOUT_COLLAPSE = 25

  def render_commit_stats(stats, diff)
    res = ["<ul class='list-group boffset0'>"]
    ind=0
    stats.files.each do |filename, adds, deletes, total|
      file_name = if diff[ind].renamed_file
          "#{diff[ind].a_path.rtruncate 60}=>#{diff[ind].b_path.rtruncate 60}"
        else
          filename.rtruncate(120)
        end

      res << "<li class='list-group-item'>"
        res << "<div class='row'>"
          res << "<div class='col-sm-8'><a href='#diff-#{ind}'>#{diff_file_icon(diff[ind])} #{h(file_name)}</a></div>"

          res << "<div class='col-sm-2'>"
            res << "<div class='pull-right'>"
              res << "<strong class='text-success'>+#{adds}</strong> <strong class='text-danger'>-#{deletes}</strong>"
            res << "</div>"
          res << "</div>"

          res << "<div class='col-sm-2'>"
            res << render_progress_bar(adds, deletes)
          res << "</div>"

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

  protected

  def commits_pluralization_arr
    pluralize ||=  t('layout.commits.pluralize').map {|base, title| title.to_s}
  end

  def render_progress_bar(adds, deletes)
    return if adds+deletes == 0
    res = ''
    pluses  = ((adds/(adds+deletes).to_f)*100).round
    minuses = 100 - pluses

    res << "<div class='progress' style='margin-bottom: 0'>"
      res << "<div class='progress-bar progress-bar-success' style='width: #{pluses}%'></div>"
      res << "<div class='progress-bar progress-bar-danger' style='width: #{minuses}%'></div>"
    res << "</div>"
    res
  end

  def diff_file_icon(diff)
    icon = if diff.renamed_file
             'fa-caret-square-o-right text-info'
           elsif diff.new_file
             'fa-plus-square text-success'
           elsif diff.deleted_file
             'fa-minus-square text-danger'
           else
             'fa-pencil-square text-warning'
           end
    "<i class='fa #{icon}'></i>"
  end
end
