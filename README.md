# lerouxdelens

Small personal homepage for [lerouxdelens.com](https://lerouxdelens.com).

## Local

Build the production image locally:

```sh
make build
```

Run the site on `http://lerouxdelens.test`:

```sh
make local-setup
make local-up
```

`make local-setup` appends `127.0.0.1 lerouxdelens.test` to `/etc/hosts`, so it
will prompt for `sudo` on machines where that is required.
`make local-up` bind-mounts the working tree into nginx, so reloading the page
shows local file changes immediately.

## Deploy

Production deploys are built from the current `HEAD` commit and pushed straight
to `vps2` over SSH:

```sh
make deploy
```

`make deploy` refuses to run if the working tree is dirty, so the exact commit
running in production is always reproducible.
