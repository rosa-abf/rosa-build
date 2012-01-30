# -*- encoding : utf-8 -*-
module DiffHelper

  def render_diff(diff)
    diff_display ||= Diff::Display::Unified.new(diff.diff)

    res = "<a name='#{h(diff.a_path)}'></a>"

    res += "<table class='diff inline' cellspacing='0' cellpadding='0'>"
    res += "<tbody>"
    res += diff_display.render(Git::Diff::InlineCallback.new)
    res += "</tbody>"
    res += "</table>"

    res.html_safe
  end

end
