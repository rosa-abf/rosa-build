json.id          advisory.id
json.advisory_id advisory.advisory_id
json.description simple_format(advisory.description)
json.references  advisory.references.split("\n").map { |ref| construct_ref_link(ref) }.join('<br />')
json.update_type advisory.update_type

