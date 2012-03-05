# -*- encoding : utf-8 -*-
module CommitHelper

  def render_commit_stats(stats)
    res = ["<table class='commit_stats'>"]
    stats.files.each do |filename, adds, deletes, total|
      res << "<tr>"
      res << "<td><a href='##{h(filename)}'>#{h(filename)}</a></td>".encode_to_default
      res << "<td class='diffstat'>"
      res << I18n.t("layout.projects.inline_changes_count", :count => total).strip +
             " (" +
             I18n.t("layout.projects.inline_additions_count", :count => adds).strip +
             ", " +
             I18n.t("layout.projects.inline_deletions_count", :count => deletes).strip +
             ")"
      res << "</td>"
    end
    res << "</table>"

    res.join("\n").encode_to_default.html_safe
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

  def shortest_hash_id(id)
    id[0..8]
  end

  def short_commit_message(message)
    # Why 42? Because it is the Answer!
    truncate(message, :length => 42, :omission => "...").encode_to_default
  end

  def commit_author_link(author)
    name = author.name.encode_to_default
    email = author.email
    u = User.where(:email => email).first
    u.present? ? link_to(name, user_path(u)) : mail_to(email, name)
  end
end
