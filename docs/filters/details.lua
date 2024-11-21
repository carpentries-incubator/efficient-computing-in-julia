function Div (elem)
    if elem.classes[1] ~= "details" then
        return
    end
    local summary = pandoc.Str("")
    elem = elem:walk{
        Header = function (head)
            summary = head.content
            return {}
        end
    }
    return pandoc.Div({
        pandoc.RawInline("html", "<details><summary>"),
        pandoc.Span(summary),
        pandoc.RawInline("html", "</summary>"),
        pandoc.Div(elem.content),
        pandoc.RawInline("html", "</details>")
    })
end

