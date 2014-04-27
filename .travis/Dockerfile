FROM debian:stretch

WORKDIR /build

# We need the directory for the «apt build-dep» command below, will be later
# overridden by -v.
COPY debian /build/debian

# We need the dependencies for the travis script, and the build dependencies.
RUN apt update -qq \
    && apt install --no-install-recommends -y \
      git wget curl ruby \
    && apt build-dep -y .
