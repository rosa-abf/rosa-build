class FeedbackMailer < ActionMailer::Base
  FBM_CONFIG = APP_CONFIG['feedback']

  default to:  FBM_CONFIG['email'],
          cc:  FBM_CONFIG['cc'],
          bcc: FBM_CONFIG['bcc']
  default_url_options.merge!(protocol: 'https') if APP_CONFIG['mailer_https_url']

  include Resque::Mailer # send email async

  def feedback_form_send(form_data)
    @data = Feedback.new(form_data)

    from = "#{@data.name} <#{@data.email}>"
    subj = prepare_subject(@data.subject)

    mail from: from, subject: subj
  end

  protected

  def prepare_subject(subject)
    res = ''
    res << affix(FBM_CONFIG['subject_prefixes'])
    res << subject
    res << affix(FBM_CONFIG['subject_postfixes'])
    res = res.strip.gsub(/\s+/, ' ')
    res
  end

  def affix(affixes)
    ' %s ' % Array(affixes).map{|e| "[#{e}]"}.join
  end
end
