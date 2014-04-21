def status_color(ni)
  case
  when ni.ready?
    :green
  when ni.disabled?
    nil
  when ni.failed?
    :red
  else
    :orange
  end
end