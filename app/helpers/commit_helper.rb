# -*- encoding : utf-8 -*-
module CommitHelper
  def render_commit_stats(stats)
    res = ["<table class='commit_stats'>"]
    ind=0
    stats.files.each do |filename, adds, deletes, total|
      res << "<tr>"
      res << "<td><a href='#diff-#{ind}'>#{h(filename.rtruncate 120)}</a></td>"
      res << "<td class='diffstat'>"
      res << I18n.t("layout.projects.inline_changes_count", :count => total).strip +
             " (" +
             I18n.t("layout.projects.inline_additions_count", :count => adds).strip +
             ", " +
             I18n.t("layout.projects.inline_deletions_count", :count => deletes).strip +
             ")"
      res << "</td>"
      ind +=1
    end
    res << "</table>"

    res.join("\n").html_safe.default_encoding!
  end

#  def format_commit_message(message)
#    h(message).gsub("\n", "<br />").html_safe
#  end

  def commit_date(date)
    I18n.localize(date, { :format => "%d %B %Y" })
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
    u = User.where(:email => email).first
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
