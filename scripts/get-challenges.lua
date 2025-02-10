function Pandoc(doc)
    local cblocks = {}
    table.insert(cblocks, pandoc.Header(1, doc.meta.title))
    for i, el in pairs(doc.blocks) do
        if (el.t == "Div" and el.classes[1] == "challenge") or
           (el.t == "Header") then
            table.insert(cblocks, el)
        end
    end
    table.insert(cblocks, pandoc.HorizontalRule())
    return pandoc.Pandoc(cblocks, doc.meta)
end
