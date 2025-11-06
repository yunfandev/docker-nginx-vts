# docker-nginx-vts

Custom Docker image based on `nginx:1.26.3` with the [nginx-module-vts](https://github.com/vozlt/nginx-module-vts) status module compiled in.

## Features

- Builds the official NGINX source for version `1.26.3` and adds the `vts` module during compilation.
- Includes a GitHub Actions workflow for publishing images to GitHub Container Registry (GHCR).

## Building the image

```bash
docker build -t nginx-vts .
```

The build process fetches the vanilla NGINX packaging for Debian, injects the module, builds the `.deb` package, and installs it into the same image.

## Publishing to GitHub Container Registry

This repository ships with a GitHub Actions workflow that publishes the image to the
[GitHub Container Registry (GHCR)](https://ghcr.io) whenever changes land on the
`master` branch, any other branch, a version tag starting with `v` is pushed, or the
workflow is triggered manually.

The workflow logs in with the repository's `GITHUB_TOKEN`, builds the image for
`linux/amd64`, and pushes a `latest` tag for `master` builds, a `dev` tag for builds
from any other branch, and semantic version tags when building from Git tags. You can
find the definition in [`.github/workflows/docker-publish.yml`](.github/workflows/docker-publish.yml).

> **Note:** The workflow originally only ran on the `main` branch, so it would not
> trigger in repositories that still use `master` as the default branch. The updated
> trigger covers all branches to ensure your pushes start a build.

To make the resulting package discoverable, ensure the image visibility is set to
public (from the GitHub UI under **Packages**) or configure any additional registry
secrets if you plan to publish to a private namespace.

## Usage

Run the container as you would the official NGINX image:

```bash
docker run --rm -p 8080:80 nginx-vts
```

To expose the VTS metrics endpoint, enable it in your NGINX configuration, for example:

```nginx
server {
    listen 80;

    location /status {
        vhost_traffic_status_display;
        vhost_traffic_status_display_format prometheus;
    }
}
```

With the configuration above, visiting `http://localhost:8080/status` will return Prometheus-formatted metrics.

## License

The project is released under [The Unlicense](./LICENSE).
