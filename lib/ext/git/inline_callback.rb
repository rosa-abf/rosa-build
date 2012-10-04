# -*- encoding : utf-8 -*-
module Git
  module Diff
    module InlineCallback
      def prepare(comments)
        @num_line, @line_comments = -1, comments
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
         </tr>
         #{render_line_comments @num_line}"
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

      def before_headerblock(block)
      end

      def after_headerblock(block)
      end

      def before_unmodblock(block)
      end

      def before_modblock(block)
      end

      def before_remblock(block)
      end

      def before_addblock(block)
      end

      def before_sepblock(block)
      end

      def before_nonewlineblock(block)
      end

      def after_unmodblock(block)
      end

      def after_modblock(block)
      end

      def after_remblock(block)
      end

      def after_addblock(block)
      end

      def after_sepblock(block)
      end

      def after_nonewlineblock(block)
      end

      def new_line
        ""
      end

      def renderer(data)
        result = []
        data.each do |block|
          result << send("before_" + classify(block), block)
          result << block.map { |line| send(classify(line), line) }
          result << send("after_" + classify(block), block)
        end
        result.compact.join(new_line)
      end

      protected

      def classify(object)
        object.class.name[/\w+$/].downcase
      end

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
        @num_line = @num_line.succ
      end

      def line_comment
        "<a href='#' class='add_line-comment'><img src='/assets/line_comment.png' alt='Add Comment'></a>"
      end

      def render_line_comments line_number
        comments = @line_comments.select{|c| c.data.try('[]', :line_number) == line_number}

        "<tr>
          <td class='line_numbers line_comments' colspan='2'></td>
          <td>#{render("projects/comments/line_list", :list => comments, :project => @project, :commentable => @commit)}</td>
         </tr>" if comments.count
      end
    end
  end
end
