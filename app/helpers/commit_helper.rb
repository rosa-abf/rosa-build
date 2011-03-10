module CommitHelper

  def render_commit_stats(stats)
    res = ["<ul class='diff_stats'>"]
    stats.files.each do |filename, adds, deletes, total|
      res << "<li>"
      res << "<a href='##{h(filename)}'>#{h(filename)}</a>&nbsp;#{total}&nbsp;"
      res << "<small class='deletions'>#{(0...deletes).map{|i| "-" }.join}</small>"
      res << "<small class='insertions'>#{(0...adds).map{|i| "+" }.join}</small>"
      res << "</li>"
    end
  res << "</ul>"

  res.join("\n")
  end

  def format_commit_message(message)
    h(message).gsub("\n", "<br />")
  end

  def commit_date(date)
    I18n.localize(date, { :format => "%d %B %Y" })
  end

end