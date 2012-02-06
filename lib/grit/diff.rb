# -*- encoding : utf-8 -*-
module Grit
  class Diff
    def self.list_from_string(repo, text)
      lines = text.split("\n")

      diffs = []

      while !lines.empty?
        m, a_path, b_path = *lines.shift.match(%r{^diff --git "{0,1}a/(.+?)"{0,1} "{0,1}b/(.+?)"{0,1}$})

        if lines.first =~ /^old mode/
          m, a_mode = *lines.shift.match(/^old mode (\d+)/)
          m, b_mode = *lines.shift.match(/^new mode (\d+)/)
        end

        if lines.empty? || lines.first =~ /^diff --git/
          diffs << Diff.new(repo, a_path, b_path, nil, nil, a_mode, b_mode, false, false, nil)
          next
        end

        sim_index    = 0
        new_file     = false
        deleted_file = false
        renamed_file = false

        if lines.first =~ /^new file/
          m, b_mode = lines.shift.match(/^new file mode (.+)$/)
          a_mode    = nil
          new_file  = true
        elsif lines.first =~ /^deleted file/
          m, a_mode    = lines.shift.match(/^deleted file mode (.+)$/)
          b_mode       = nil
          deleted_file = true
        elsif lines.first =~ /^similarity index (\d+)\%/
          sim_index    = $1.to_i
          renamed_file = true
          2.times { lines.shift } # shift away the 2 `rename from/to ...` lines
        end

        m, a_blob, b_blob, b_mode = *lines.shift.match(%r{^index ([0-9A-Fa-f]+)\.\.([0-9A-Fa-f]+) ?(.+)?$})
        b_mode.strip! if b_mode

        diff_lines = []
        while lines.first && lines.first !~ /^diff/
          diff_lines << lines.shift
        end
        diff = diff_lines.join("\n")

        diffs << Diff.new(repo, a_path, b_path, a_blob, b_blob, a_mode, b_mode, new_file, deleted_file, diff, renamed_file, sim_index)
      end

      diffs
    end
  end
end
