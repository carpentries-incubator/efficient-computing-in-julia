.PHONY: serve podman

serve:
	R --no-save -e 'sandpaper::serve()'

podman:
	podman run -it --replace --name efficient-julia -v $$(pwd):/lesson --security-opt label=disable --network=host sandpaper

docker:
	docker run -it --name efficient-julia -v $$(pwd):/lesson --security-opt label=disable --network=host sandpaper

exercises.md: scripts/get-challenges.lua $(wildcard episodes/*.md)
	for f in episodes/*.md; do \
		pandoc --lua-filter scripts/get-challenges.lua $$f -t markdown; \
	done > $@
