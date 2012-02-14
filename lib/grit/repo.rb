# -*- encoding : utf-8 -*-
module Grit
  class Repo

    def diff_with_encoding(a, b, *paths)
      diff = self.git.native('diff', {}, a, b, '--', *paths).encode_to_default
      if diff =~ /diff --git "{0,1}a/
        diff = diff.sub(/.*?(diff --git "{0,1}a)/m, '\1')
      else
        diff = ''
      end
      Diff.list_from_string(self, diff)
    end
    alias_method_chain :diff, :encoding

  end
end
