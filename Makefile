.PHONY: serve podman

serve:
	R --no-save -e 'sandpaper::serve()'

podman:
	podman run -it --replace --name efficient-julia -v $$(pwd):/lesson --security-opt label=disable --network=host sandpaper

docker:
	docker run -it --name efficient-julia -v $$(pwd):/lesson --security-opt label=disable --network=host sandpaper

