class SpecLexer < Rouge::RegexLexer
  tag 'rpmspec'
  aliases 'spec'
  filenames '*.spec'
  mimetypes 'text/x-rpm-spec'

  title 'RPM Spec'
  desc 'RPM Spec package build description language'

  # it is used in several places with deferent outcomes, so it is defined here
  DIRECTIVE_REGEXP = %r(
    ^
    (%(?:package|prep|build|install|clean|check|pre[a-z]*|post[a-z]*|trigger[a-z]*|files))
    (.*)
    $
  )x

  state :root do
    rule /#.*\n/, Comment
    mixin :basic
  end

  state :description do
    rule DIRECTIVE_REGEXP do |m|
      groups Name::Decorator, Text
      pop!
    end
    rule /\n/, Text
    rule /./, Text
  end

  state :changelog do
    rule /\*.*\n/, Generic::Subheading
    rule DIRECTIVE_REGEXP do |m|
      groups Name::Decorator, Text
      pop!
    end
    rule /\n/, Text
    rule /./, Text
  end

  state :string do
    rule /"/, Literal::String::Double, :pop!
    rule /\\([\\abfnrtv"']|x[a-fA-F0-9]{2,4}|[0-7]{1,3})/, Literal::String::Escape
    mixin :interpol
    rule /./, Literal::String::Double
    rule /\n/, Text, :pop!
  end

  state :basic do
    mixin :macro
    rule %r(
      ^
      (Name|Version|Release|Epoch|Summary|Group|License|Packager|
      Vendor|Icon|URL|Distribution|Prefix|Patch[0-9]*|Source[0-9]*|
      Requires\(?[a-z]*\)?|[a-z]+Req|Obsoletes|Suggests|Provides|Conflicts|
      Build[a-z]+|[a-z]+Arch|Auto[a-z]+)
      (:)
      (.*)
      $
    )xi do |m|
      groups Generic::Heading, Punctuation
      delegate self.class, m[3]
    end
    rule /^%description/, Name::Decorator, :description
    rule /^%changelog/, Name::Decorator, :changelog
    rule DIRECTIVE_REGEXP do |m|
      groups Name::Decorator, Text
    end
    rule %r(
      %(attr|defattr|dir|doc(?:dir)?|setup|config(?:ure)?|
      make(?:install)|ghost|patch[0-9]+|find_lang|exclude|verify)
    )x, Keyword
    mixin :interpol
    rule /'.*?'/, Literal::String::Single
    rule /"/, Literal::String::Double, :string
    rule /\n/, Text
    rule /./, Text
  end

  state :macro do
    rule /%define.*\n/, Comment::Preproc
    rule /%\{\!\?.*%define.*\}/, Comment::Preproc
    rule /(%(?:if(?:n?arch)?|else(?:if)?|endif))(.*)$/ do |m|
      groups Comment::Preproc, Text, Text
    end
  end

  state :interpol do
    rule /%\{?__[a-z_]+\}?/, Name::Function
    rule /%\{?_([a-z_]+dir|[a-z_]+path|prefix)\}?/, Keyword::Pseudo
    rule /%\{\?\w+\}/, Name::Variable
    rule /\$\{?RPM_[A-Z0-9_]+\}?/, Name::Variable::Global
    rule /%\{[a-zA-Z]\w+\}/, Keyword::Constant
  end
end
