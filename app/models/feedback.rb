# This class is based on
# https://github.com/rails/rails/blob/4da6e1cce2833474034fda0cbb67b2cc35e828da/activerecord/lib/active_record/validations.rb

class Feedback
  include ActiveModel::Conversion
  include ActiveModel::Validations
  include ActiveModel::Serializers::JSON
  include ActiveModel::MassAssignmentSecurity
  extend  ActiveModel::Naming

  attr_accessor :name, :email, :subject, :message

  attr_accessible :name, :email, :subject, :message

  validates :name,    :presence => true
  validates :email,   :presence => true,
                      :format => { :with => /\A[^@]+@([^@\.]+\.)+[^@\.]+\z/, :allow_blank => false }
  validates :subject, :presence => true
  validates :message, :presence => true

  def initialize(args = {}, options = {})
    return args.dup if args.is_a? Feedback
    if args.respond_to? :name and args.respond_to? :email
      self.name, self.email = args.name, args.email
    elsif args.respond_to? :each_pair
      sanitize_for_mass_assignment(args, options[:as]).each_pair do |k, v|
        send("#{k}=", v)
      end
    else
      return false
    end
  end

  # FIXME: Maybe rename to `save`?
  def perform_send(options = {})
    perform_validations(options) ? real_send : false
  end

  def perform_send!(options={})
    perform_validations(options) ? real_send : raise(ActiveRecord::RecordInvalid.new(self))
  end

  def new_record?
    true
  end

  def persisted?
    false
  end

  def message_with_links
    message.to_s.dup.auto_link
  end

  def attributes
    %w{ name email subject message }.inject({}) do |h, e|
      h.merge(e => send(e))
    end
  end

  def to_s
    str = "#<#{self.class} "
    str += %w{ name email subject message }.inject('') do |s, e|
      s << "#{e}: #{ send(e).inspect }, "; s
    end
    str[-2] = '>'
    str[0..-1]
  end

  class << self

    def create(attributes = nil, options = {}, &block)
      if attributes.is_a?(Array)
        attributes.collect { |attr| create!(attr, options, &block) }
      else
        object = new(attributes, options)
        yield(object) if block_given?
        object.perform_send
        object
      end
    end

    def create!(attributes = nil, options = {}, &block)
      if attributes.is_a?(Array)
        attributes.collect { |attr| create!(attr, options, &block) }
      else
        object = new(attributes, options)
        yield(object) if block_given?
        object.perform_send!
        object
      end
    end

  end

  protected

  def real_send
    FeedbackMailer.feedback_form_send(self).deliver
  end

  def perform_validations(options={})
    perform_validation = options[:validate] != false
    perform_validation ? valid?(options[:context]) : true
  end

end
Feedback.include_root_in_json = false
