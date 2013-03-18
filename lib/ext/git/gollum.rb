module Gollum
  class Wiki
    # Public: Applies a reverse diff for a given page.  If only 1 SHA is given,
    # the reverse diff will be taken from its parent (^SHA...SHA).  If two SHAs
    # are given, the reverse diff is taken from SHA1...SHA2.
    #
    # page   - The Gollum::Page to delete.
    # sha1   - String SHA1 of the earlier parent if two SHAs are given,
    #          or the child.
    # sha2   - Optional String SHA1 of the child.
    # commit - The commit Hash details:
    #          :message - The String commit message.
    #          :name    - The String author full name.
    #          :email   - The String email address.
    #          :parent  - Optional Grit::Commit parent to this update.
    #
    # Returns a String SHA1 of the new commit, or nil if the reverse diff does
    # not apply.
    def revert_page_with_committer(page, sha1, sha2 = nil, commit = {})
      if sha2.is_a?(Hash)
        commit = sha2
        sha2   = nil
      end

      multi_commit = false

      patch     = full_reverse_diff_for(page, sha1, sha2)
      committer = if obj = commit[:committer]
        multi_commit = true
        obj
      else
        Committer.new(self, commit)
      end
      parent    = committer.parents[0]
      committer.options[:tree] = @repo.git.apply_patch(parent.sha, patch)
      return false unless committer.options[:tree]
      committer.after_commit do |index, sha|
        @access.refresh

        files = []
        if page
          files << [page.path, page.name, page.format]
        else
          # Grit::Diff can't parse reverse diffs.... yet
          patch.each_line do |line|
            if line =~ %r{^diff --git b/.+? a/(.+)$}
              path = $1
              ext  = ::File.extname(path)
              name = ::File.basename(path, ext)
              if format = ::Gollum::Page.format_for(ext)
                files << [path, name, format]
              end
            end
          end
        end

        files.each do |(path, name, format)|
          dir = ::File.dirname(path)
          dir = '' if dir == '.'
          index.update_working_dir(dir, name, format)
        end
      end

      multi_commit ? committer : committer.commit
    end
    alias_method_chain :revert_page, :committer

    def revert_commit_with_committer(sha1, sha2 = nil, commit = {})
      revert_page_with_committer(nil, sha1, sha2, commit)
    end
    alias_method_chain :revert_commit, :committer
  end
end
