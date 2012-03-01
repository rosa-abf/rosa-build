# -*- encoding : utf-8 -*-
class BuildList::Filter
  def initialize(project, user, options = {})
    @project = project
    @user = user
    set_options(options)
  end

  def find
    build_lists =  @project ? @project.build_lists : BuildList.scoped

    if @options[:bs_id]
      build_lists = build_lists.where(:bs_id => @options[:bs_id])
    else
      build_lists = build_lists.accessible_by(::Ability.new(@user), @options[:ownership].to_sym) if @options[:ownership]
      build_lists = build_lists.for_status(@options[:status]) if @options[:status]
      build_lists = build_lists.scoped_to_arch(@options[:arch_id]) if @options[:arch_id]
      build_lists = build_lists.scoped_to_project_version(@options[:project_version]) if @options[:project_version]
      build_lists = build_lists.scoped_to_is_circle(@options[:is_circle]) if @options[:is_circle].present?
      build_lists = build_lists.scoped_to_project_name(@options[:project_name]) if @options[:project_name]

      if @options[:created_at_start] || @options[:created_at_end]
        build_lists = build_lists.for_creation_date_period(@options[:created_at_start], @options[:created_at_end])
      end
      if @options[:notified_at_start] || @options[:notified_at_end]
        build_lists = build_lists.for_notified_date_period(@options[:notified_at_start], @options[:notified_at_end])
      end
    end

    build_lists
  end

  def respond_to?(name)
    return true if @options.has_key?(name)
    super
  end

  def method_missing(name, *args, &block)
    @options.has_key?(name) ? @options[name] : super
  end

  private

  def set_options(options)
    @options = HashWithIndifferentAccess.new(options.reverse_merge({
        :ownership => nil,
        :status => nil,
        :created_at_start => nil,
        :created_at_end => nil,
        :notified_at_start => nil,
        :notified_at_end => nil,
        :arch_id => nil,
        :is_circle => nil,
        :project_version => nil,
        :bs_id => nil,
        :project_name => nil
    }))

    @options[:ownership] = @options[:ownership].presence || 'owned'
    @options[:status] = @options[:status].present? ? @options[:status].to_i : nil
    @options[:created_at_start] = build_date_from_params(:created_at_start, @options)
    @options[:created_at_end] = build_date_from_params(:created_at_end, @options)
    @options[:notified_at_start] = build_date_from_params(:notified_at_start, @options)
    @options[:notified_at_end] = build_date_from_params(:notified_at_end, @options)
    @options[:project_version] = @options[:project_version].presence
    @options[:arch_id] = @options[:arch_id].present? ? @options[:arch_id].to_i : nil
    @options[:is_circle] = @options[:is_circle].present? ? @options[:is_circle] == "1" : nil
    @options[:bs_id] = @options[:bs_id].presence
    @options[:project_name] = @options[:project_name].presence
  end

  def build_date_from_params(field_name, params)
    if params["#{field_name}(1i)"].present? || params["#{field_name}(2i)"].present? || params["#{field_name}(3i)"].present?
      Date.civil((params["#{field_name}(1i)"].presence || Date.today.year).to_i, 
                 (params["#{field_name}(2i)"].presence || Date.today.month).to_i,
                 (params["#{field_name}(3i)"].presence || Date.today.day).to_i)
    else
      nil
    end
  end
end
