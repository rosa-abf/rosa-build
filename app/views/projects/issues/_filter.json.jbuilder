json.kind            params[:kind]
json.filter          params[:filter]
json.sort            params[:sort]
json.sort_direction  params[:direction]
json.status          params[:status]

if @all_issues
  json.all_count       @all_issues.not_closed_or_merged.count
  if current_user
    json.assigned_count  @assigned_issues.not_closed_or_merged.count
    json.created_count   @created_issues.not_closed_or_merged.count
  end
  json.opened_count    @opened_issues.count
  json.closed_count    @closed_issues.count
  json.filtered_count  @issues.count
end
json.page            params[:page]
