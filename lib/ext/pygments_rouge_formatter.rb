class PygmentsRougeFormatter < Rouge::Formatters::HTML
  def initialize(mode = :normal)
    @mode = mode
  end

  def stream(tokens, &b)
    case @mode
    when :normal
      stream_normal(tokens, &b)
    when :blame
      stream_blame(tokens, &b)
    else
      stream_normal(tokens, &b)
    end
  end

  private

  def stream_normal(tokens, &b)
    linecnt = 1
    formatted = String.new('')
    token_lines(tokens).each do |line_tokens|
      formatted << "<span id=\"ln-#{linecnt}\"><a name=\"lc-#{linecnt}\"></a>"
      line_tokens.each do |token, value|
        formatted << span(token, value)
      end
      formatted << "</span>\n"
      linecnt += 1
    end

    formatted_line_numbers = (1..(linecnt - 1)).map do |lineno|
      "<a href=\"#lc-#{lineno}\">#{lineno}</a>"
    end.join("\n") << "\n"

    buffer = [%(<table class="highlighttable"><tbody><tr>)]
    buffer << %(<td class="linenos">)
    buffer << %(<div class="linenodiv"><pre>#{formatted_line_numbers}</pre></dev>)
    buffer << '</td>'
    buffer << %(<td class="code"><div class="highlight"><pre>)
    buffer << formatted
    buffer << '</pre></div></td>'
    buffer << '</tr></tbody></table>'

    yield buffer.join
  end

  def stream_blame(tokens, &b)
    yield "<div class=\"highlight\"><pre>"
    token_lines(tokens).each do |line_tokens|
      line_tokens.each { |t, v| yield span(t, v) }
    end
    yield "</pre></div>"
  end
end
