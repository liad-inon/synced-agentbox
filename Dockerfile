# syntax=docker/dockerfile:1
ARG BASE_IMAGE=ghcr.io/madarco/agentbox/box:latest
FROM ${BASE_IMAGE}

# Runtime must bind the host repository here; VOLUME alone creates an empty,
# Docker-managed volume. Keep upstream tools, user, entrypoint and /workspace.
VOLUME ["/repo"]
