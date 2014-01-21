json.array!(advisories) do |json, a|
  json.id            a.advisory_id
  json.advisory_id   a.advisory_id
  json.description   simple_format(a.description)
  json.popover_desc  truncate(a.description, length: 500);
  json.references    a.references.split("\n").map{|ref| construct_ref_link(ref)}.join('<br />')
  json.update_type   a.update_type
end
