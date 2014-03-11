# This module is based on
# https://github.com/gitlabhq/gitlabhq/blob/397c3da9758c03a215a308c011f94261d9c61cfa/lib/gitlab/markdown.rb

# Custom parser for GitLab-flavored Markdown
#
# It replaces references in the text with links to the appropriate items in
# GitLab.
#
# Supported reference formats are:
#   * @foo for team members
#   * for issues & pull requests:
#   * #123
#   * abf#123
#   * abf/rosa-build#123
#   * 123456 for commits
#
# It also parses Emoji codes to insert images. See
# http://www.emoji-cheat-sheet.com/ for a list of the supported icons.
#
# Examples
#
#   >> gfm("Hey @david, can you fix this?")
#   => "Hey <a href="/users/david">@david</a>, can you fix this?"
#
#   >> gfm("Commit 35d5f7c closes #1234")
#   => "Commit <a href="/gitlab/commits/35d5f7c">35d5f7c</a> closes <a href="/gitlab/issues/1234">#1234</a>"
#
#   >> gfm(":trollface:")
#   => "<img alt=\":trollface:\" class=\"emoji\" src=\"/images/trollface.png" title=\":trollface:\" />
module MarkdownHelper
  include IssuesHelper

  attr_reader :html_options

  # Public: Parse the provided text with GitLab-Flavored Markdown
  #
  # text         - the source text
  # html_options - extra options for the reference links as given to link_to
  #
  # Note: reference links will only be generated if @project is set
  def gfm(text, html_options = {})
    return text if text.nil?

    # Duplicate the string so we don't alter the original, then call to_str
    # to cast it back to a String instead of a SafeBuffer. This is required
    # for gsub calls to work as we need them to.
    text = text.dup.to_str

    @html_options = html_options

    # Extract pre blocks so they are not altered
    # from http://github.github.com/github-flavored-markdown/
    text.gsub!(%r{<pre>.*?</pre>|<code>.*?</code>}m) { |match| extract_piece(match) }
    # Extract links with probably parsable hrefs
    text.gsub!(%r{<a.*?>.*?</a>}m) { |match| extract_piece(match) }
    # Extract images with probably parsable src
    text.gsub!(%r{<img.*?>}m) { |match| extract_piece(match) }

    # TODO: add popups with additional information

    text = parse(text)

    # Insert pre block extractions
    text.gsub!(/\{gfm-extraction-(\h{32})\}/) do
      insert_piece($1)
    end

    sanitize text.html_safe, attributes: ActionView::Base.sanitized_allowed_attributes + %w(id class)
  end

  private

  def extract_piece(text)
    @extractions ||= {}

    md5 = Digest::MD5.hexdigest(text)
    @extractions[md5] = text
    "{gfm-extraction-#{md5}}"
  end

  def insert_piece(id)
    @extractions[id]
  end

  # Private: Parses text for references and emoji
  #
  # text - Text to parse
  #
  # Note: reference links will only be generated if @project is set
  #
  # Returns parsed text
  def parse(text)
    parse_references(text) if @project
    parse_emoji(text)

    text
  end

  REFERENCE_PATTERN = %r{
    (?<prefix>[\W\/])?                                                     # Prefix
    (                                                                      # Reference
       @(?<user>[a-zA-Z][a-zA-Z0-9_\-\.]*)                                 # User/Group uname
      |(?<issue>(?:[a-zA-Z0-9\-_]*\/)?(?:[a-zA-Z0-9\-_]*)?\#[0-9]+)        # Issue ID
      |(?<commit>[\h]{6,40})                                               # Commit ID
    )
    (?<suffix>\W)?                                                         # Suffix
  }x.freeze

  TYPES = [:user, :issue, :commit].freeze

  def parse_references(text)
    # parse reference links
    text.gsub!(REFERENCE_PATTERN) do |match|
      prefix     = $~[:prefix]
      suffix     = $~[:suffix]
      type       = TYPES.select{|t| !$~[t].nil?}.first
      identifier = $~[type]

      # Avoid HTML entities
      if prefix && suffix && prefix[0] == '&' && suffix[-1] == ';'
        match
      elsif ref_link = reference_link(type, identifier)
        "#{prefix}#{ref_link}#{suffix}"
      else
        match
      end
    end
  end

  EMOJI_PATTERN = %r{(:(\S+):)}.freeze

  def parse_emoji(text)
    # parse emoji
    text.gsub!(EMOJI_PATTERN) do |match|
      if valid_emoji?($2)
        image_tag(image_path("emoji/#{$2}.png"), class: 'emoji', title: $1, alt: $1, size: "20x20")
      else
        match
      end
    end
  end

  # Private: Checks if an emoji icon exists in the image asset directory
  #
  # emoji - Identifier of the emoji as a string (e.g., "+1", "heart")
  #
  # Returns boolean
  def valid_emoji?(emoji)
    Emoji.names.include? emoji
  end

  # Private: Dispatches to a dedicated processing method based on reference
  #
  # reference  - Object reference ("@1234", "!567", etc.)
  # identifier - Object identifier (Issue ID, SHA hash, etc.)
  #
  # Returns string rendered by the processing method
  def reference_link(type, identifier)
    send("reference_#{type}", identifier)
  end

  def reference_user(identifier)
    member = User.where(uname: identifier).first || Group.where(uname: identifier).first
    if member
      link_to("@#{identifier}", "/#{identifier}", html_options.merge(title: member.fullname, class: "gfm gfm-member #{html_options[:class]}"))
    end
  end

  def reference_issue(identifier)
    if issue = Issue.find_by_hash_tag(identifier, current_ability, @project)
      if issue.pull_request
        title = "#{PullRequest.model_name.human}: #{issue.title}"
        url = project_pull_request_path(issue.project, issue.pull_request)
      else
        title = "#{Issue.model_name.human}: #{issue.title}"
        url = project_issue_path(issue.project.owner, issue.project.name, issue.serial_id)
      end
      link_to(identifier, url, html_options.merge(title: title, class: "gfm gfm-issue #{html_options[:class]}"))
    end
  end

  def reference_commit(identifier)
    if commit = @project.repo.commit(identifier)
      link_to shortest_hash_id(commit.id), commit_path(@project, commit.id)
      title = GitPresenters::CommitAsMessagePresenter.present(commit, project: @project) do |presenter|
        link_to(identifier, commit_path(@project, commit), html_options.merge(title: presenter.caption, class: "gfm gfm-commit #{html_options[:class]}"))
      end
    end
  end
end
