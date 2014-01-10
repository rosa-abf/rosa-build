# This class is based on
# https://github.com/gitlabhq/gitlabhq/blob/2bc78739a7aa9d7e5109281fc45dbd41a1a576d4/lib/gitlab/markdown.rb
class Redcarpet::Render::GitlabHTML < Redcarpet::Render::HTML

  attr_reader :template
  alias_method :h, :template

  def initialize(template, options = {})
    @template = template
    @project = @template.instance_variable_get("@project")
    super options
  end

  def block_code(code, language)
    # New lines are placed to fix an rendering issue
    # with code wrapped inside <h1> tag for next case:
    #
    # # Title kinda h1
    #
    #     ruby code here
    #
    code_class = "class=\"#{language.downcase}\"" if language.present?
    <<-HTML

       <pre><code #{code_class}>#{code}</code></pre>

    HTML
  end

  def link(link, title, content)
    h.link_to_gfm(content, link, title: title)
  end

  def postprocess(full_document)
    h.gfm(full_document)
  end
end
