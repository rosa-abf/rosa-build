# -*- encoding : utf-8 -*-
class BuildList::Filter
  PER_PAGE = [25, 50, 100]

  attr_reader :options

  def initialize(project, user, current_ability, options = {})
    @project, @user, @current_ability = project, user, current_ability
    set_options(options)
  end

  def find
    build_lists =  @project ? @project.build_lists : BuildList.scoped

    if @options[:id]
      build_lists = build_lists.where(:id => @options[:id])
    else
      build_lists = build_lists.scoped_to_new_core(@options[:new_core] == '0' ? nil : true) if @options[:new_core].present?
      build_lists = build_lists.by_mass_build(@options[:mass_build_id]) if @options[:mass_build_id]
      build_lists = build_lists.accessible_by(@current_ability, @options[:ownership].to_sym) if @options[:ownership]

      build_lists = build_lists.for_status(@options[:status])
                               .scoped_to_arch(@options[:arch_id])
                               .scoped_to_save_platform(@options[:platform_id])
                               .scoped_to_project_version(@options[:project_version])
                               .scoped_to_project_name(@options[:project_name])
                               .for_notified_date_period(@options[:updated_at_start], @options[:updated_at_end])
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
        :ownership        => nil,
        :status           => nil,
        :updated_at_start => nil,
        :updated_at_end   => nil,
        :arch_id          => nil,
        :platform_id      => nil,
        :is_circle        => nil,
        :project_version  => nil,
        :id               => nil,
        :project_name     => nil,
        :mass_build_id    => nil,
        :new_core         => nil
    }))

    @options[:ownership] = @options[:ownership].presence || (@project || !@user ? 'everything' : 'owned')
    @options[:status] = @options[:status].present? ? @options[:status].to_i : nil
    @options[:created_at_start] = build_date_from_params(:created_at_start, @options)
    @options[:created_at_end] = build_date_from_params(:created_at_end, @options)
    @options[:updated_at_start] = build_date_from_params(:updated_at_start, @options)
    @options[:updated_at_end] = build_date_from_params(:updated_at_end, @options)
    @options[:project_version] = @options[:project_version].presence
    @options[:arch_id] = @options[:arch_id].try(:to_i)
    @options[:platform_id] = @options[:platform_id].try(:to_i)
    @options[:is_circle] = @options[:is_circle].present? ? @options[:is_circle] == "1" : nil
    @options[:id] = @options[:id].presence
    @options[:project_name] = @options[:project_name].presence
    @options[:mass_build_id] = @options[:mass_build_id].presence
    @options[:new_core] = @options[:new_core].presence
  end

  def build_date_from_params(field_name, params)
    return nil if params[field_name].blank?
    params[field_name].strip!
    return Date.parse(params[field_name]) if params[field_name] =~ /\A\d{2}\/\d{2}\/\d{4}\z/
    return Time.at(params[field_name].to_i) if params[field_name] =~ /\A\d+\z/
    nil
  end
end
