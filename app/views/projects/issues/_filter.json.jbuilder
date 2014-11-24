json.kind            params[:kind]
json.filter          params[:filter]
json.sort            params[:sort]
json.sort_direction  params[:direction]
json.status          params[:status]

json.all_count       @all_issues.not_closed_or_merged.count
json.assigned_count  (current_user ? @assigned_issues.not_closed_or_merged.count : 0)
json.created_count   @created_issues.not_closed_or_merged.count
json.opened_count    @opened_issues.count
json.closed_count    @closed_issues.count
json.page            params[:page]
json.filtered_count  @issues.count
