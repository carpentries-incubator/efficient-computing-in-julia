function Meta(meta)
    if meta.contents_file ~= nil then
        local f = io.open(meta.contents_file, "r")
        local contents = pandoc.read(f:read("a"), "markdown")
        meta.contents = contents.blocks
    end
    return meta
end
