module WikiHelper
  class CompareHelper

    def initialize(diff, versions)
      @diff = diff
      @versions = versions
    end

    def before
      @versions[0][0..6]
    end

    def after
      @versions[1][0..6]
    end

    def lines
      lines = []
      @diff.diff.split("\n")[2..-1].each do |line|
        lines << { :line  => line,
                   :class => line_class(line),
                   :ldln  => left_diff_line_number(line),
                   :rdln  => right_diff_line_number(line) }
      end if @diff
      lines
    end

    def show_revert
      !@message
    end

    private

      def line_class(line)
        if line =~ /^@@/
          'gc'
        elsif line =~ /^\+/
          'gi'
        elsif line =~ /^\-/
          'gd'
        else
          ''
        end
      end

      @left_diff_line_number = nil
      def left_diff_line_number(line)
        if line =~ /^@@/
          m, li = *line.match(/\-(\d+)/)
          @left_diff_line_number = li.to_i
          @current_line_number = @left_diff_line_number
          ret = '...'
        elsif line[0] == ?-
          ret = @left_diff_line_number.to_s
          @left_diff_line_number += 1
          @current_line_number = @left_diff_line_number - 1
        elsif line[0] == ?+
          ret = ' '
        else
          ret = @left_diff_line_number.to_s
          @left_diff_line_number += 1
          @current_line_number = @left_diff_line_number - 1
        end
        ret
      end

      @right_diff_line_number = nil
      def right_diff_line_number(line)
        if line =~ /^@@/
          m, ri = *line.match(/\+(\d+)/)
          @right_diff_line_number = ri.to_i
          @current_line_number = @right_diff_line_number
          ret = '...'
        elsif line[0] == ?-
          ret = ' '
        elsif line[0] == ?+
          ret = @right_diff_line_number.to_s
          @right_diff_line_number += 1
          @current_line_number = @right_diff_line_number - 1
        else
          ret = @right_diff_line_number.to_s
          @right_diff_line_number += 1
          @current_line_number = @right_diff_line_number - 1
        end
        ret
      end
  end

  def gravatar_url(email)
    "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email.downcase)}?s=16&r=pg"
  end

  def escaped_name
    CGI.escape(@name)
  end

  def editor_path(project, name)
    if @new
      url_for(:controller => :wiki, :action => :create, :project_id => project.id)
    else
      url_for(:controller => :wiki, :action => :update, :project_id => project.id, :id => name)
    end
  end

  def view_path(project, name)
    name == 'Home' ? project_wiki_index_path(project) : project_wiki_path(project, name)
  end

  def formats
    Gollum::Page::FORMAT_NAMES.map do |key, val|
      [ val, key.to_s ]
    end.sort do |a, b|
      a.first.downcase <=> b.first.downcase
    end
  end

  def footer
    if @footer.nil?
      @footer = !!@page.footer ? @page.footer.raw_data : false
    end
    @footer
  end

  def sidebar
    if @sidebar.nil?
      @sidebar = !!@page.sidebar ? @page.sidebar.raw_data : false
    end
    @sidebar
  end

  def has_footer?
    @footer = (@page.footer || false) if @footer.nil? && @page
    !!@footer
  end

  def has_sidebar?
    @sidebar = (@page.sidebar || false) if @sidebar.nil? && @page
    !!@sidebar
  end

  def footer_content
    has_footer? && @footer.formatted_data
  end

  def footer_format
    has_footer? && @footer.format.to_s
  end

  def sidebar_content
    has_sidebar? && @sidebar.formatted_data
  end

  def sidebar_format
    has_sidebar? && @sidebar.format.to_s
  end

  def author
    @page.version.author.name
  end

  def date
    @page.version.authored_date.strftime("%Y-%m-%d %H:%M:%S")
  end

  def format
    @new ? 'markdown' : @page.format
  end
end
