Title = "unknown"

function Meta(meta)
    Title = meta.title
end

function Pandoc(doc)
    return pandoc.Pandoc{Title}
end
