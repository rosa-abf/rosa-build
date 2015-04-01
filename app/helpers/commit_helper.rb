module CommitHelper
  MAX_FILES_WITHOUT_COLLAPSE = 25

  def render_commit_stats(stats)
    res = ["<table class='table table-responsive boffset0'>"]
    ind=0
    stats.files.each do |filename, adds, deletes, total|
      res << "<tr>"
      res << "<td><a href='#diff-#{ind}'>#{h(filename.rtruncate 120)}</a></td>"
      res << "<td class='diffstat'>"
      res << I18n.t("layout.projects.inline_changes_count", count: total).strip +
             " (" +
             I18n.t("layout.projects.inline_additions_count", count: adds).strip +
             ", " +
             I18n.t("layout.projects.inline_deletions_count", count: deletes).strip +
             ")"
      res << "</td>"
      ind +=1
    end
    res << "</table>"

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

  protected

  def commits_pluralization_arr
    pluralize ||=  t('layout.commits.pluralize').map {|base, title| title.to_s}
  end
end
