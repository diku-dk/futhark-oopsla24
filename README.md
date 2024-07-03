# Meta-Artifact for the paper *AUTOMAP: Inferring Rank-Polymorphic Function Applications with Integer Linear Programming*

This repository contains a Nix derivation for building the artifact (a
Docker image) for the paper. See [benchmarks/](benchmarks/) for the
actual benchmarking infrastructure, including dependencies, if you
want to run it outside docker.

## (Re-)creating the Docker image

You must have [Nix](https://nixos.org/) and then run

```
$ nix-build docker.nix
```

This produces a file called `result` (a symlink to the actual image,
which is in the Nix store), which you can load with:

```
$ docker load -i result
```

And then run with:

```
$ docker run -it futhark-oopsla24:latest
```

See [benchmarks/README.md](benchmarks/README.md) for further
instructions.
