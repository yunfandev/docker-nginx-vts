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
