module Git
  module Diff
    class InlineCallback < ::Diff::Renderer::Base      
      def addline(line)
        "<tr class='changes'>
          <td></td>
          <td class='line_numbers'></td>
          <td class='line_numbers'>#{line.new_number}</td>
          <td class='code ins'>#{render_line(line)}</td>
        </tr>"
      end
      
      def remline(line)
        "<tr class='changes'>
          <td></td>
          <td class='line_numbers'>#{line.old_number}</td>
          <td class='line_numbers'></td>
          <td class='code del'>#{render_line(line)}</td>
        </tr>"
      end

      def modline(line)
        "<tr clas='chanes line'>
          <td></td>
          <td class='line_numbers'>#{line.old_number}</td>
          <td class='line_numbers'>#{line.new_number}</td>
          <td class='code unchanged modline'>#{render_line(line)}</td>
        </tr>"
      end
      
      def unmodline(line)
        "<tr class='changes unmodline'>
          <td></td>
          <td class='line_numbers'>#{line.old_number}</td>
          <td class='line_numbers'>#{line.new_number}</td>
          <td class='code unchanged unmodline'>#{render_line(line)}</td>
        </tr>"
      end
      
      def sepline(line)
        "<tr class='changes hunk-sep'>
          <td></td>
          <td class='line_numbers line_num_cut'>&hellip;</td>
          <td class='line_numbers line_num_cut'>&hellip;</td>
          <td class='code cut-line'></td>
        </tr>"
      end
      
      def nonewlineline(line)
        "<tr class='changes'>
          <td></td>
          <td class='line_numbers'>#{line.old_number}</td>
          <td class='line_numbers'>#{line.new_number}</td>
          <td class='code modline unmodline'>#{render_line(line)}</td>
        </tr>"
      end

      protected
      def escape(str)
        str.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&#34;')
      end

      def render_line(line)
        res = '<span class="diff-content">'
        if line.inline_changes?
          prefix, changed, postfix = line.segments.map{|segment| escape(segment) }
          res += "#{prefix}<span class='idiff'>#{changed}</span>#{postfix}"
        else
          res += escape(line)
        end
        res += '</span>'
        
        res
      end
    end
  end
end
