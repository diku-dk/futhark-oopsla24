# Artifact for the paper *AUTOMAP: Inferring Rank-Polymorphic Function Applications with Integer Linear Programming*

## Requirements

The following system requirements are satisfied by the Docker image,
and are only listed for completeness.

PATH must contain two compiler binaries `futhark-original` and
`futhark-automap`, corresponding to the unmodified and AUTOMAP-enabled
Futhark compiler.

The following tools must also be available:

* [scc](https://github.com/boyter/scc)

* [hyperfine](https://github.com/sharkdp/hyperfine)

* [gnuplot](http://gnuplot.info/)

## Reproducing experiments

Running `make` will reproduce the quantitative evaluation discussed in
Section 9 of the paper. This takes about TBD minutes on a modern
computer. The results are printed on the terminal as they come in, and
are also stored as files in the `results/` directory. A `data/`
directory containing raw (unprocessed) data is also constructed, but
can be ignored.

The following specific metrics are reproduced by the artifact.

* Fig. 12 is available as `reports/ilps.pdf`.

* The metrics on Fig. 13 are available in multiple files.

  * Number of programs and lines of code are in `reports/lines.txt`.

  * Change in maps is the last line of `reports/maps.txt`.

  * Largest, median, and mean ILP is in TODO

  * The mean type checking slowdown is the last line of
    `reports/tctime.txt`.

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
