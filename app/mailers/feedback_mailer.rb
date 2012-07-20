class FeedbackMailer < ActionMailer::Base
  FBM_CONFIG = APP_CONFIG['feedback']

  default :to  => FBM_CONFIG['email'],
          :cc  => FBM_CONFIG['cc'],
          :bcc => FBM_CONFIG['bcc']

  include Resque::Mailer # send email async

  def feedback_form_send(form_data)
    @data = Feedback.new(form_data)

    from = "#{@data.name} <#{@data.email}>"
    subj = prepare_subject(@data.subject)

    mail :from => from, :subject => subj
  end

  protected

  def prepare_subject(subject)
    res = ''
    res << affix(FBM_CONFIG['subject_prefixes'])
    res << subject
    res << affix(FBM_CONFIG['subject_postfixes'])
    # WOODOO magic. Change all space sequences to one space than remove trailing spaces.
    res.gsub(/\s+/, ' ').gsub(/^\s|\s$/, '')
    res
  end

  def affix(affixes)
    res = ' '
    res << Array(affixes).map{|e| "[#{e}]"}.join
    res << ' '
    res
  end

end
