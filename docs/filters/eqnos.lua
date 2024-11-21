EqCounter = 1
EqMap = {}

-- function Para(elem)
--     if #elem.content < 2 then
--         return
--     end
--     if elem.content[1].t ~= "Math" and elem.content[2].t == "Str"
-- end

function Span(elem)
	if elem.identifier:match("eq:%S+") then
		-- table.insert(elem.content[1].classes, "numbered")
		-- print(elem.content[1])
		-- elem.content[1].text = elem.content[1].text .. "\\quad{\\rm(" .. EqCounter .. ")}"
		local number = pandoc.Span(pandoc.Str("(" .. EqCounter .. ")"), { class = "equation-number" })
		print("setting " .. elem.identifier .. " to " .. EqCounter)
		EqMap[elem.identifier] = EqCounter
		EqCounter = EqCounter + 1
		return pandoc.Span({ elem.content[1], number }, { id = elem.identifier, class = "equation" })
		-- style="display: block; position: relative; width: 100%; text-align: center;"})
	end
end

function Str(elem)
	ref, rest = elem.text:match("@(eq:[a-z-]+)(.*)")
	if ref == nil then
		return
	end
	if rest == nil then
		rest = ""
	end
	if EqMap[ref] == nil then
		print("Equation reference not found: " .. ref)
		return
	end
	return { pandoc.Link(pandoc.Str("(" .. EqMap[ref] .. ")"), "#" .. ref), pandoc.Str(rest) }
end

function Cite(elem)
	if #elem.citations == 1 and elem.citations[1].id:match("eq:%S+") then
		local id = elem.citations[1].id
		if EqMap[id] == nil then
			print("Not found: " .. id)
			return
		end
		return pandoc.Link(pandoc.Str("(" .. EqMap[id] .. ")"), "#" .. id)
	end
end

function Link(elem)
	if elem.target:match("#eq:%S+") then
		table.insert(elem.classes, "eqref")
		table.insert(elem.content, pandoc.Str(" " .. EqMap[elem.target:sub(2)]))
		return elem
	end
end
