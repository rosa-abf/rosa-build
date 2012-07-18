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
      build_lists = build_lists.scoped_to_save_platform(@options[:platform_id]) if @options[:platform_id]
      build_lists = build_lists.scoped_to_project_version(@options[:project_version]) if @options[:project_version]
      build_lists = build_lists.scoped_to_is_circle(@options[:is_circle]) if @options[:is_circle].present?
      build_lists = build_lists.scoped_to_project_name(@options[:project_name]) if @options[:project_name]
      build_lists = build_lists.by_mass_build(@options[:mass_build_id]) if @options[:mass_build_id]

# TODO [BuildList#created_at filters] Uncomment here and in build_lists/_filter.html.haml to return filters
#
#      if @options[:created_at_start] || @options[:created_at_end]
#        build_lists = build_lists.for_creation_date_period(@options[:created_at_start], @options[:created_at_end])
#      end
      if @options[:updated_at_start] || @options[:updated_at_end]
        build_lists = build_lists.for_notified_date_period(@options[:updated_at_start], @options[:updated_at_end])
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
        :updated_at_start => nil,
        :updated_at_end => nil,
        :arch_id => nil,
        :platform_id => nil,
        :is_circle => nil,
        :project_version => nil,
        :bs_id => nil,
        :project_name => nil,
        :mass_build_id => nil
    }))

    @options[:ownership] = @options[:ownership].presence || (@project || !@user ? 'everything' : 'owned')
    @options[:status] = @options[:status].present? ? @options[:status].to_i : nil
    @options[:created_at_start] = build_date_from_params(:created_at_start, @options)
    @options[:created_at_end] = build_date_from_params(:created_at_end, @options)
    @options[:updated_at_start] = build_date_from_params(:updated_at_start, @options)
    @options[:updated_at_end] = build_date_from_params(:updated_at_end, @options)
    @options[:project_version] = @options[:project_version].presence
    @options[:arch_id] = @options[:arch_id].present? ? @options[:arch_id].to_i : nil
    @options[:platform_id] = @options[:platform_id].present? ? @options[:platform_id].to_i : nil
    @options[:is_circle] = @options[:is_circle].present? ? @options[:is_circle] == "1" : nil
    @options[:bs_id] = @options[:bs_id].presence
    @options[:project_name] = @options[:project_name].presence
    @options[:mass_build_id] = @options[:mass_build_id].presence
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
