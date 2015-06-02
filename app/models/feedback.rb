# This class is based on
# https://github.com/rails/rails/blob/4da6e1cce2833474034fda0cbb67b2cc35e828da/activerecord/lib/active_record/validations.rb

class Feedback
  include ActiveModel::Conversion
  include ActiveModel::Validations
  include ActiveModel::Serializers::JSON
  extend  ActiveModel::Naming

  self.include_root_in_json = false

  attr_accessor :name, :email, :subject, :message

  validates :name, :subject, :message, presence: true
  validates :email, presence: true,
                    format: { with: /\A[^@]+@([^@\.]+\.)+[^@\.]+\z/,
                              allow_blank: false }

  def initialize(args = {}, options = {})
    return args.dup if args.is_a? Feedback
    if args.respond_to? :name and args.respond_to? :email
      self.name, self.email = args.name, args.email
    elsif args.respond_to? :each_pair
      args.each_pair do |k, v|
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
    str = %w{ name email subject message }.map do |e|
      "#{e}: #{ send(e).inspect }"
    end.join(', ')
    return "#<#{self.class} #{str}>"
  end

  class << self

    def create(attributes = nil, options = {}, &block)
      do_create(attributes, options, false, &block)
    end

    def create!(attributes = nil, options = {}, &block)
      do_create(attributes, options, true, &block)
    end

    protected

    def do_create(attributes = nil, options = {}, bang = false, &block)
      if attributes.is_a?(Array)
        attributes.collect { |attr| do_create(attr, options, bang, &block) }
      else
        object = new(attributes, options)
        yield(object) if block_given?
        bang ? object.perform_send! : object.perform_send
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
