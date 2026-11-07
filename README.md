# synced-agentbox

A general image derived from `ghcr.io/madarco/agentbox/box:latest`.
The only image change is a declared `/repo` volume. All upstream tools, user,
entrypoint, command and `/workspace` behavior are inherited. No project files,
credentials, extra runtimes or agents are baked in.

## Shared base repository

A bind mount exposes the same files on the host and in the container, including
Git-ignored files. Writes, renames and deletions are immediately shared in both
directions. There is no copying service or conflict resolver. Coordinate edits
to the same files. The container can access and change everything in this mount.

Pull the image:

```bash
docker pull ghcr.io/liad-inon/synced-agentbox:latest
```

From this checkout, start the environment against any existing repository:

```bash
export REPO_PATH="$HOME/Code/your-project"
docker compose up -d
docker compose exec dev bash
# Inside the container:
cd /repo
```

The host repo is `/repo`; `/workspace` is left available for separate working
copies. Files in `/repo` persist on the host. Packages installed elsewhere in the
container survive stop/start, but are lost when that container is replaced.
`docker compose stop` / `docker compose start` reuse it. `up` can replace it when
the image changes; save or reproduce environment changes before upgrading.

For a single interactive session without Compose:

```bash
docker run --rm -it --mount "type=bind,src=$REPO_PATH,dst=/repo" \
  --workdir /repo ghcr.io/liad-inon/synced-agentbox:latest bash
```

The image does not ship project credentials. Configure agent authentication in
the environment separately. Its user is inherited from upstream (`vscode`);
host repo permissions must allow that UID to read/write (normally UID 1000).
Compose intentionally does not mount the host Docker socket or home directory.
It does not enable nested Docker or reproduce AgentBox's host relay.

## AgentBox CLI compatibility

AgentBox accepts this image:

```bash
agentbox codex --image ghcr.io/liad-inon/synced-agentbox:latest
```

However, that command alone does **not** bind your host repo at `/repo`.
AgentBox 0.33.0 has no public extra-mount option and seeds its own `/workspace`
from Git. Docker's `VOLUME` instruction creates an anonymous volume when no mount
is provided; it cannot select a host path. Use the Compose/direct-Docker launcher
above for the shared-repo behavior. Those containers are not managed AgentBox
boxes and do not appear in its dashboard. Herdr on the host can run their terminal
commands normally; this image does not add a Herdr installation.

## Build and publishing

```bash
docker build --pull -t synced-agentbox:dev .
bash tests/shared-repo.sh synced-agentbox:dev
```

GitHub Actions builds from fresh upstream `latest`, verifies shared ignored files
and writes in both directions, then publishes the exact tested amd64 image to
GHCR. Pushes to `main`, daily scheduled runs and manual runs publish `latest` and
`sha-<commit>` tags. A `v*` Git tag additionally publishes that version tag.
Pull requests build/test without publishing. A scheduled rebuild of the same
commit may use a newer upstream base, so use an image digest for immutable pins.

The package must be public for anonymous pulls. GitHub initially creates GHCR
packages as private even for public repositories: change the package visibility
to public in its Package settings after the first publish. Private packages can
be pulled after `docker login ghcr.io` with a token granting `read:packages`.

References: [upstream AgentBox](https://github.com/madarco/agentbox),
[GHCR publishing](https://docs.github.com/en/actions/tutorials/publish-packages/publish-docker-images).
