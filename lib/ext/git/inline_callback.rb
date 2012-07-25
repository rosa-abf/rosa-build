# -*- encoding : utf-8 -*-
module Git
  module Diff
    class InlineCallback < ::Diff::Renderer::Base
      def before_headerblock(block)
      end

      def after_headerblock(block)
      end

      def headerline(line)
        set_line_number
        "<tr class='header'>
          <td class='line_numbers'>...</td>
          <td class='line_numbers'>...</td>
          <td class='header'>#{line}</td>
        </tr>"
      end

      def addline(line)
        set_line_number
        "<tr class='changes'>
          <td class='line_numbers'></td>
          <td class='line_numbers'>#{line.new_number}</td>
          <td class='code ins'>
            #{line_comment}
            <pre>#{render_line(line)}</pre>
          </td>
        </tr>"
      end

      def remline(line)
        set_line_number
        "<tr class='changes'>
          <td class='line_numbers'>#{line.old_number}</td>
          <td class='line_numbers'></td>
          <td class='code del'>
            #{line_comment}
            <pre>#{render_line(line)}</pre>
          </td>
        </tr>"
      end

      def modline(line)
        set_line_number
        "<tr clas='chanes line'>
          <td class='line_numbers'>#{line.old_number}</td>
          <td class='line_numbers'>#{line.new_number}</td>
          <td class='code unchanged modline'>
            #{line_comment}
            <pre>#{render_line(line)}</pre>
          </td>
        </tr>"
      end

      def unmodline(line)
        set_line_number
        "<tr class='changes unmodline'>
          <td class='line_numbers'>#{line.old_number}</td>
          <td class='line_numbers'>#{line.new_number}</td>
          <td class='code unchanged unmodline'>
            #{line_comment}
            <pre>#{render_line(line)}</pre>
          </td>
        </tr>"
      end

      def sepline(line)
        "<tr class='changes hunk-sep'>
          <td class='line_numbers line_num_cut'>&hellip;</td>
          <td class='line_numbers line_num_cut'>&hellip;</td>
          <td class='code cut-line'></td>
        </tr>"
      end

      def nonewlineline(line)
        set_line_number
        "<tr class='changes'>
          <td class='line_numbers'>#{line.old_number}</td>
          <td class='line_numbers'>#{line.new_number}</td>
          <td class='code modline unmodline'>
            #{line_comment}
            <pre>#{render_line(line)}</pre>
          </td>
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

      def set_line_number
        @num_line = (@num_line || -1).succ
      end

      def line_comment
        "<a href='#' class='add_line-comment'><img src='/assets/line_comment.png' alt='Add Comment'></a>"
      end
    end
  end
end
