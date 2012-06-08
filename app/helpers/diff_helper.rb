# -*- encoding : utf-8 -*-
module DiffHelper

  def render_diff(diff)
    diff_display ||= Diff::Display::Unified.new(diff.diff)

    #res = "<a name='#{h(diff.a_path)}'></a>"

    res = "<table class='diff inline' cellspacing='0' cellpadding='0'>"
    res += "<tbody>"
    res += diff_display.render(Git::Diff::InlineCallback.new)
    res += "</tbody>"
    res += "</table>"

    res.html_safe
  end

  def render_diff_stats(stats)
    res = ["<table class='commit_stats'>"]
    stats.each_with_index do |stat, ind|
      res << "<tr>"
      res << "<td><a href='#diff-#{ind}'>#{h(stat.filename.rtruncate 120)}</a></td>"
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

end
