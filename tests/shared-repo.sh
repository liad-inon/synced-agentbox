#!/usr/bin/env bash
set -euo pipefail
image=${1:?Usage: tests/shared-repo.sh IMAGE}
repo=$(mktemp -d)
trap 'rm -rf "$repo"' EXIT
chmod 0777 "$repo"
printf '.ignored-setup\n' > "$repo/.gitignore"
printf 'host setup\n' > "$repo/.ignored-setup"
docker run --rm --mount "type=bind,src=$repo,dst=/repo" \
  --entrypoint bash "$image" -euc '
    test "$(cat /repo/.ignored-setup)" = "host setup"
    printf "container update\n" > /repo/.ignored-setup
    printf "container file\n" > /repo/from-container
  '
test "$(cat "$repo/.ignored-setup")" = 'container update'
test "$(cat "$repo/from-container")" = 'container file'
echo 'Shared ignored files and container-to-host writes verified.'
