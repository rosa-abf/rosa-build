# -*- encoding : utf-8 -*-
module Diff::Display
  # Processes the diff and generates a Data object which contains the
  # resulting data structure.
  #
  # The +run+ class method is fed a diff and returns a Data object. It will
  # accept as its argument a String, an Array or a File object (or anything 
  # that responds to #each):
  #
  #   Diff::Display::Unified::Generator.run(diff)
  #
  class Data < Array
    def initialize
      super
      @stats = {:additions => 0, :deletions => 0}
    end
 
    def stats
      each do |block|
        block.each do |line|
          case line
          when Diff::Display::AddLine
            @stats[:additions] += 1
          when Diff::Display::RemLine
            @stats[:deletions] += 1
          end
        end
      end
      @stats
    end
          
    def to_diff
      diff = ""
      each do |block|
        block.each do |line|
          line_str = line.expand_inline_changes_with(nil, nil)
          case line
          when HeaderLine
            diff << "#{line_str}\n"
          when UnModLine
            diff << " #{line_str}\n"
          when SepLine
            diff << "\n"
          when AddLine
            diff << "+#{line_str}\n"
          when RemLine
            diff << "-#{line_str}\n"
          when NonewlineLine
            diff << line_str
          end
        end
      end
      diff.chomp
    end
          
    def debug
      demodularize = Proc.new {|obj| obj.class.name[/\w+$/]}
      each do |diff_block|
        print "-" * 40, ' ', demodularize.call(diff_block)
        puts
        puts diff_block.map {|line| 
          # "%5d" % line.old_number + 
          "%8s" % "[#{line.old_number || '.'} #{line.new_number || '.'}]" +
          " [#{demodularize.call(line)}#{'(i)' if line.inline_changes?}]" +
          line
        }.join("\n")
        puts "-" * 40, ' ' 
      end
      nil
    end
  end
  
  class Line < String
    class << self
      def add(line, line_number, inline = false, offsets = [])
        AddLine.new(line, line_number, inline, offsets)
      end
    
      def rem(line, line_number, inline = false, offsets = [])
        RemLine.new(line, line_number, inline, offsets)
      end
    
      def unmod(line, old_number, new_number)
        UnModLine.new(line, old_number, new_number)
      end
      
      def nonewline(line)
        NonewlineLine.new(line)
      end
      
      def header(line)
        HeaderLine.new(line)
      end
    end
    
    def initialize(line, old_number = nil, new_number = nil)
      super(line)
      @old_number, @new_number = old_number, new_number
      @inline = false
    end
    attr_reader :old_number, :new_number
    
    def identifier
      self.class.name[/\w+$/].gsub(/Line$/, "").downcase.to_sym
    end
    
    def inline_changes?
      # Is set in the AddLine+RemLine subclasses
      @inline
    end
    
    # returns the prefix, middle and postfix parts of a line with inline changes
    def segments
      return self.dup unless inline_changes?
      prefix, changed = self.dup.split('\\0')
      changed, postfix = changed.split('\\1')
      [prefix, changed, postfix]
    end
    
    # Expand any inline changes with +prefix+ and +postfix+
    def expand_inline_changes_with(prefix, postfix)
      return self.dup unless inline_changes?
      str = self.dup
      str.sub!('\\0', prefix.to_s)
      str.sub!('\\1', postfix.to_s)
      str
    end
    
    def inspect
      %Q{#<#{self.class.name} [#{old_number.inspect}-#{new_number.inspect}] "#{self}">}
    end
  end

  class AddLine < Line
    def initialize(line, line_number, inline = false, offsets = [])
      super(line, nil, line_number)
      @inline = inline
      @offsets = offsets
    end
    attr_reader :offsets
  end
  
  class RemLine < Line
    def initialize(line, line_number, inline = false, offsets = [])
      super(line, line_number, nil)
      @inline = inline
      @offsets = offsets
    end
    attr_reader :offsets
  end
  
  class NonewlineLine < Line
    def initialize(line = '\\ No newline at end of file')
      super(line)
    end      
  end
  
  class UnModLine < Line
    def initialize(line, old_number, new_number)
      super(line, old_number, new_number)
    end
  end
  
  class SepLine < Line
    def initialize(line = '...')
      super(line)
    end
  end
  
  class HeaderLine < Line
    def initialize(line)
      super(line)
    end
  end
  
  # This class is an array which contains Line objects. Just like Line
  # classes, several Block classes inherit from Block. If all the lines
  # in the block are added lines then it is an AddBlock. If all lines
  # in the block are removed lines then it is a RemBlock. If the lines
  # in the block are all unmodified then it is an UnMod block. If the
  # lines in the block are a mixture of added and removed lines then
  # it is a ModBlock. There are no blocks that contain a mixture of
  # modified and unmodified lines.
  class Block < Array
    class << self
      def add;    AddBlock.new    end 
      def rem;    RemBlock.new    end
      def mod;    ModBlock.new    end
      def unmod;  UnModBlock.new  end
      def header; HeaderBlock.new end
      def nonewline; NonewlineBlock.new end
    end
  end

  #:stopdoc:#
  class AddBlock    < Block;  end  
  class RemBlock    < Block;  end
  class ModBlock    < Block;  end
  class UnModBlock  < Block;  end
  class SepBlock    < Block;  end
  class HeaderBlock < Block;  end
  class NonewlineBlock < Block; end
  #:startdoc:#
  
  
  class Unified::Generator
    
    # Extracts the line number info for a given diff section
    LINE_NUM_RE = /^@@ [+-]([0-9]+)(?:,([0-9]+))? [+-]([0-9]+)(?:,([0-9]+))? @@/
    LINE_TYPES  = {'+' => :add, '-' => :rem, ' ' => :unmod, '\\' => :nonewline}
    
    # Runs the generator on a diff and returns a Data object
    def self.run(udiff)
      raise ArgumentError, "Object must be enumerable" unless udiff.respond_to?(:each_line)
      generator = new
      udiff.each_line do |line|
        begin
          generator.process(line.chomp)
        rescue ArgumentError => e
          e.message =~ /^invalid byte sequence/ ? next : raise(e)
        end
      end
      generator.finish
      generator.data
    end
    
    def initialize
      @buffer         = []
      @line_type      = nil
      @prev_line_type = nil
      @offset         = [0, 0]
      @data = Data.new
      self
    end
    
    # Finishes up with the generation and returns the Data object (could
    # probably use a better name...maybe just #data?)
    def data
      @data
    end
    
    # This method is called once the generator is done with the unified
    # diff. It is a finalizer of sorts. By the time it is called all data
    # has been collected and processed.
    def finish
      # certain things could be set now that processing is done
      #identify_block
    end
    
    def process(line)      
      if is_header_line?(line)
        push Block.header
        current_block << Line.header(line)
        return
      end
      
      if line =~ LINE_NUM_RE
        push Block.header
        current_block << Line.header(line)
        add_separator unless @offset[0].zero?
        @line_type = nil
        @offset    = Array.new(2) { $3.to_i - 1 }
        return
      end
      
      @line_type, line = LINE_TYPES[car(line)], cdr(line)
      
      if @line_type == :add && @prev_line_type == :rem
        @offset[0] -= 1
        @buffer.push current_block.pop
        @buffer.push line
        process_block(:mod, false)
        return
      end
      
      if LINE_TYPES.values.include?(@line_type)
        @buffer.push(line.to_s)
        process_block(@line_type, true)
      end
      
    end
    
    protected
      def is_header_line?(line)
        return true if ['+++ ', '--- '].include?(line[0,4])
        return true if line =~ /^(new|delete) file mode [0-9]+$/
        return true if line =~ /^diff \-\-git/
        return true if line =~ /^index \w+\.\.\w+( [0-9]+)?$/i
        false
      end

      def process_block(diff_line_type, isnew = false)
        @data.pop unless isnew
        push Block.send(diff_line_type)
        
        current_line = @buffer.pop
        return unless current_line
        
        # \\ No newline at end of file
        if diff_line_type == :nonewline
          current_block << Line.nonewline('\\ No newline at end of file')
          return
        end
        
        if isnew
          process_line(current_line, diff_line_type)
        else
          process_lines_with_differences(@buffer.shift, current_line)
          raise "buffer exceeded #{@buffer.inspect}" unless @buffer.empty?
        end
      end
      
      def process_line(line, type, inline = false)
        case type
          when :add
            @offset[1] += 1
            current_block << Line.send(type, line, @offset[1], inline, @offset.dup)
          when :rem
            @offset[0] += 1
            current_block << Line.send(type, line, @offset[0], inline, @offset.dup)
          # when :rmod
          #   @offset[0] += 1
          #   @offset[1] += 1 # TODO: is that really correct?
          #   current_block << Line.send(@prev_line_type, line, @offset[0])
          when :unmod
            @offset[0] += 1
            @offset[1] += 1
            current_block << Line.send(type, line, *@offset)
        end
        @prev_line_type = type
      end

      # TODO Needs a better name...it does process a line (two in fact) but
      # its primary function is to add a Rem and an Add pair which
      # potentially have inline changes
      def process_lines_with_differences(oldline, newline)
        start, ending = get_change_extent(oldline, newline)
        
        if start.zero? && ending.zero?
          process_line(oldline, :rem, false) # -
          process_line(newline, :add, false) # +
        else
          # -
          line = inline_diff(oldline, start, ending)
          process_line(line, :rem, true)
          # +
          line = inline_diff(newline, start, ending)
          process_line(line, :add, true)
        end
      end
      
      # Inserts string formating characters around the section of a string
      # that differs internally from another line so that the Line class
      # can insert the desired formating
      def inline_diff(line, start, ending)
        if start != 0 || ending != 0
          last = ending + line.length
          str = line[0...start] + '\0' + line[start...last] + '\1' + line[last...line.length]
        end
        str || line
      end
      
      def add_separator
        push SepBlock.new 
        current_block << SepLine.new
      end

      def car(line)
        line[0,1]
      end

      def cdr(line)
        line[1..-1]
      end

      # Returns the current Block object
      def current_block
        @data.last
      end

      # Adds a Line object onto the current Block object 
      def push(line)
        @data.push line
      end

      # Determines the extent of differences between two string. Returns
      # an array containing the offset at which changes start, and then 
      # negative offset at which the chnages end. If the two strings have
      # neither a common prefix nor a common suffic, [0, 0] is returned.
      def get_change_extent(str1, str2)
        start = 0
        limit = [str1.size, str2.size].sort.first
        while start < limit and str1[start, 1] == str2[start, 1]
          start += 1
        end
        ending = -1
        limit -= start
        while -ending <= limit and str1[ending, 1] == str2[ending, 1]
          ending -= 1
        end

        return [start, ending + 1]
      end
  end
end
