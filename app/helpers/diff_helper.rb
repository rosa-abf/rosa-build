module DiffHelper
  def render_inline_diff(commit, diff)
    [render_inline_diff_header(commit, diff), render_inline_diff_body(diff.diff), render_inline_diff_footer].join("\n")
  end

  def render_inline_diff_header(commit, diff)
    res = "<a name='#{h(diff.a_path)}'></a>"
    if diff.b_path.present?
      res += link_to("view file @ #{commit.id}", blob_commit_path(@platform.name, @project.name, commit.id, diff.b_path))
      res += "<br />"
    end

    res += "<table class='diff inline'>
      <thead>
        <tr>
          <td class='comments'>&nbsp;</td>
          <td class='line_numbers'></td>
          <td class='line_numbers'></td>
          <td class=''>&nbsp;</td>
        </tr>
      </thead>"

    res
  end

  def render_inline_diff_body(diff)
    diff_display ||= Diff::Display::Unified.new(diff)
    "<tbody>
    #{diff_display.render(Git::Diff::InlineCallback.new)}
    </tbody>"
  end

  def render_inline_diff_footer
    "</table>"
  end
end