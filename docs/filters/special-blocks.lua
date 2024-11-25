local function Set (list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

function Div(elem)
    local s = Set{"keypoints", "questions", "objectives", "challenge", "instructor"}
    if s[elem.classes[1]] then
        table.insert(elem.classes, "special")
        return elem
    end

    if elem.classes[1] == "solution" then
        return {pandoc.RawBlock("html", "<details><summary>Solution</summary>"),
            elem,
            pandoc.RawBlock("html", "</details>")}
    end
end
