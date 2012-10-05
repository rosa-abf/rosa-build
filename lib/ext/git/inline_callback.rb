# -*- encoding : utf-8 -*-
module Git
  module Diff
    class InlineCallback < ::Diff::Renderer::Base
      def initialize diff, url, diff_counter
        @num_line, @filepath, @url, @diff_counter = -1, diff.a_path, url, diff_counter
        @line_comments = @comments.select{|c| c.data.try('[]', :path) == @path}
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
          #{td_line_link "diff-F#{@diff_counter}R#{line.new_number}", line.new_number}
          <td class='code ins'>
            #{line_comment}
            <pre>#{render_line(line)}</pre>
          </td>
         </tr>
         #{render_line_comments}"
      end

      def remline(line)
        set_line_number
        "<tr class='changes'>
          #{td_line_link "diff-F#{@diff_counter}L#{line.old_number}", line.old_number}
          <td class='line_numbers'></td>
          <td class='code del'>
            #{line_comment}
            <pre>#{render_line(line)}</pre>
          </td>
        </tr>
        #{render_line_comments}"
      end

      def modline(line)
        set_line_number
        "<tr clas='chanes line'>
          #{td_line_link "diff-F#{@diff_counter}L#{line.old_number}", line.old_number}
          #{td_line_link "diff-F#{@diff_counter}R#{line.new_number}", line.new_number}
          <td class='code unchanged modline'>
            #{line_comment}
            <pre>#{render_line(line)}</pre>
          </td>
        </tr>
        #{render_line_comments}"
      end

      def unmodline(line)
        set_line_number
        "<tr class='changes unmodline'>
          #{td_line_link "diff-F#{@diff_counter}L#{line.old_number}", line.old_number}
          #{td_line_link "diff-F#{@diff_counter}R#{line.new_number}", line.new_number}
          <td class='code unchanged unmodline'>
            #{line_comment}
            <pre>#{render_line(line)}</pre>
          </td>
        </tr>
        #{render_line_comments}"
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
          #{td_line_link "diff-F#{@diff_counter}L#{line.old_number}", line.old_number}
          #{td_line_link "diff-F#{@diff_counter}R#{line.new_number}", line.new_number}
          <td class='code modline unmodline'>
            #{line_comment}
            <pre>#{render_line(line)}</pre>
          </td>
        </tr>
        #{render_line_comments}"
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
        link_to image_tag('line_comment.png', :alt => t('layout.comments.new_header')), new_line_commit_comment_path(@project, @commit, :path => @filepath, :line => @num_line), :class => 'add_line-comment'
      end

      def render_line_comments
        comments = @line_comments.select{|c| c.data.try('[]', :line) == @num_line.to_s}
        "<tr>
          <td class='line_numbers line_comments' colspan='2'>#{comments.count}</td>
          <td>#{render("projects/comments/line_list", :list => comments, :project => @project, :commentable => @commit)}</td>
         </tr>" if comments.count > 0
      end

      def td_line_link id, num
        "<td class='line_numbers' id='#{id}'><a href='#{@url}##{id}'>#{num}</a></td>"
      end
    end
  end
end
