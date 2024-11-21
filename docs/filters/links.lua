function Link(elem)
	if elem.target:match("%.md$") then
		local new_link = elem.target:gsub("%.md$", ".html")
		elem.target = new_link
		return elem
	end
end
