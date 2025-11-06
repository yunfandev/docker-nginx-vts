# docker-nginx-vts

Custom Docker image based on `nginx:1.26.3` with the [nginx-module-vts](https://github.com/vozlt/nginx-module-vts) status module compiled in.

## Features

- Builds the official NGINX source for version `1.26.3` and adds the `vts` module during compilation.
- Verifies the upstream NGINX GPG signing key fingerprint before enabling the Debian source repository.
- Multi-stage build keeps the final image minimal by discarding build toolchains and temporary artifacts.

## Building the image

```bash
docker build -t nginx-vts .
```

The build stage fetches the vanilla NGINX packaging for Debian, injects the module, and produces a `.deb` package that is installed in the runtime stage.

## Publishing to GitHub Container Registry

This repository ships with a GitHub Actions workflow that publishes the image to the
[GitHub Container Registry (GHCR)](https://ghcr.io) whenever changes land on the
`main` branch, a version tag starting with `v` is pushed, or the workflow is
triggered manually.

The workflow logs in with the repository's `GITHUB_TOKEN`, builds the image for
`linux/amd64`, and pushes tags that reflect the branch or tag name. You can find the
definition in [`.github/workflows/docker-publish.yml`](.github/workflows/docker-publish.yml).

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

The project is licensed under [The Unlicense](./LICENSE).
