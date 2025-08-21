.PHONY: snap-lite upload
snap-lite:
	./snapctl snap-lite
upload:
	GH_TOKEN=$${GH_TOKEN} ./snapctl snap-lite --upload gist
