class BuildList::Filter

  def initialize(project, options = {})
    @project = project

    set_options(options)
  end

  def find
    if @project.nil?
      build_lists = BuildList.recent
    else
      build_lists = @project.build_lists.recent
    end

    build_lists = build_lists.for_status(@options[:status]) if @options[:status]
    build_lists = build_lists.scoped_to_arch(@options[:arch_id]) if @options[:arch_id]
    build_lists = build_lists.scoped_to_project_version(@options[:project_version]) if @options[:project_version]
    build_lists = build_lists.scoped_to_is_circle(@options[:is_circle]) if @options[:is_circle].present?

    if @options[:created_at_start] || @options[:created_at_end]
      build_lists = build_lists.for_creation_date_period(@options[:created_at_start], @options[:created_at_end])
    end

    if @options[:notified_at_start] || @options[:notified_at_end]
      build_lists = build_lists.for_notified_date_period(@options[:notified_at_start], @options[:notified_at_end])
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
          :status => nil,
          :created_at_start => nil,
          :created_at_end => nil,
          :notified_at_start => nil,
          :notified_at_end => nil,
          :arch_id => nil,
          :is_circle => nil,
          :project_version => nil
                                                                     }))

      @options[:status] = @options[:status].present? ? @options[:status].to_i : nil
      @options[:created_at_start] = build_date_from_params(:created_at_start, @options)
      @options[:created_at_end] = build_date_from_params(:created_at_end, @options)
      @options[:notified_at_start] = build_date_from_params(:notified_at_start, @options)
      @options[:notified_at_end] = build_date_from_params(:notified_at_end, @options)
      @options[:project_version] = @options[:project_version].present? ? @options[:project_version] : nil
      @options[:arch_id] = @options[:arch_id].present? ? @options[:arch_id].to_i : nil
      @options[:is_circle] = @options[:is_circle].present? ? @options[:is_circle] == "1" : nil
    end

    def build_date_from_params(field_name, params)
      if params["#{field_name.to_s}(1i)"].present? || params["#{field_name.to_s}(2i)"].present? || params["#{field_name.to_s}(3i)"].present?
        Date.civil(params["#{field_name.to_s}(1i)"].to_i, params["#{field_name.to_s}(2i)"].to_i, params["#{field_name.to_s}(3i)"].to_i)
      else
        nil
      end
    end

end