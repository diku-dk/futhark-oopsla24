# Artifact for the paper *AUTOMAP: Inferring Rank-Polymorphic Function Applications with Integer Linear Programming*

This artifact takes the form of a Docker image
`futhark-oopsla24.tar.gz`. You can load it into Docker with this
command:

```
$ docker load -i futhark-oopsla24.tar.gz
```

(Depending on your system configuration, this may or may not require
root access.)

You can then run the Docker image with this command:

```
$ docker run -it futhark-oopsla24:latest
```

## Requirements

The following system requirements are satisfied by the Docker image,
and are only listed for the sake of completeness.

PATH must contain two compiler binaries `futhark-original` and
`futhark-automap`, corresponding to the unmodified and AUTOMAP-enabled
Futhark compiler.

The following tools must also be available:

* [scc](https://github.com/boyter/scc)

* [hyperfine](https://github.com/sharkdp/hyperfine)

* [gnuplot](http://gnuplot.info/)

* [bc](https://www.gnu.org/software/bc/)

## Reproducing experiments

Running `make` will reproduce the quantitative evaluation discussed in
Section 9 of the paper. This takes about TBD minutes on a modern
computer. The results are printed on the terminal as they come in, and
are also stored as files in the `results/` directory. A `data/`
directory containing raw (unprocessed) data is also constructed, but
can be ignored. Its contents are described further down for the
benefit of future users who want to more deeply investigate the
results. Finally, the artifact reproduces Fig. 12 and Fig. 13 from the
paper.

* Fig. 12 is available as `reports/fig12.pdf`, and is also printed as
  a best-effort ASCII plot to the terminal.

* Fig. 13 is available as `reports/fig13.txt`, and is also printed to
  the terminal.

## Interactive use

If desired, AUTOMAP can be tried by starting a REPL with

```
$ futhark-automap repl
```

and entering valid expressions. Examples:

```
> [1,2,3] + 2
[3, 4, 5]
>  [1,2,3] * transpose (rep [4,5,6])
[[4, 8, 12],
 [5, 10, 15],
 [6, 12, 18]]
```

## Raw data files



## Manifest

This section describes every top-level file and directory in the
artifact and its purpose.

* `data.sh`: The main data analysis script, invoked by `Makefile`.

* `findilps.awk`: An Awk script that extracts ILP programs from
  compiler logs.

* `futhark-benchmarks-automap`: The Futhark benchmark suite modified
  to take advantage of `automap`.

* `futhark-benchmarks-original`: The unmodified Futhark benchmark
  suite.

* `Makefile`: A simplistic Makefile that simply runs `data.sh`.

More files and directories are created as part of the artifact as
discussed above.
