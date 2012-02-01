# -*- encoding : utf-8 -*-
module Grit
  class Repo

    alias_method :native_grit_diff, :diff

    def diff(a, b, *paths)
      diff = self.git.native('diff', {}, a, b, '--', *paths).force_encoding(Encoding.default_internal || Encoding::UTF_8)
      Grit.log 'in grit'
      Grit.log diff
      if diff =~ /diff --git "{0,1}a/
        diff = diff.sub(/.*?(diff --git "{0,1}a)/m, '\1')
      else
        diff = ''
      end
      Diff.list_from_string(self, diff)
    end

  end
end
