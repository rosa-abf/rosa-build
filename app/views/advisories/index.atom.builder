atom_feed do |feed|
  feed.title(t("layout.advisories.atom_title"))
  feed.updated(@advisories.first.created_at) if @advisories.length > 0

  @advisories.each do |advisory|
    feed.entry(advisory, url: advisory_url(advisory)) do |entry|
      content = raw(render(inline: true, partial: 'feed_partial', locals: { advisory: advisory }))

      entry.title("#{t("activerecord.models.advisory")} #{advisory.advisory_id}")
      entry.content(content, type: 'html')

    end
  end
end
