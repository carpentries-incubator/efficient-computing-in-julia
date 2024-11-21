function Para(elem)
    if #elem.content < 3 then
        return
    end
    if elem.content[1].t ~= "Str" or elem.content[1].text ~= "!include" then
        return
    end
    if elem.content[3].t ~= "Str" then
        print("Don't know how to include: "..elem.content[3])
        return
    end
    local filename = elem.content[3].text
    local content = io.input(filename):read("a")
    return pandoc.read(content).blocks
end
