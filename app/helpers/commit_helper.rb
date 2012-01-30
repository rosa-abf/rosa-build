# -*- encoding : utf-8 -*-
module CommitHelper

  def render_commit_stats(stats)
    res = ["<table class='commit_stats'>"]
    stats.files.each do |filename, adds, deletes, total|
      res << "<tr>"
      res << "<td><a href='##{h(filename)}'>#{h(filename)}</a></td>"
      res << "<td>#{total}</td>"
      res << "<td><small class='deletions'>#{(0...deletes).map{|i| "-" }.join}</small>"
      res << "<small class='insertions'>#{(0...adds).map{|i| "+" }.join}</small></td>"
      res << "</tr>"
    end
    res << "</table>"

    res.join("\n").html_safe
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
    truncate(message, :length => 42, :omission => "...")
  end

end
