#!/bin/bash

entangled tangle
brei weave

browser-sync start -w -s "docs/site" &
browser_sync_pid=$!

while true; do
  echo "Watching for changes"
  inotifywait -r -e close_write docs episodes || break
  entangled tangle
  brei weave
done

kill -INT ${browser_sync_pid}
