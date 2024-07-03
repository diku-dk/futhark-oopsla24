#!/bin/sh
#
# Analyse original and automap-modified benchmark programs and produce
# quantified information about how they differ. This is done by
# inspecting their diffs. Also produces plots and other statistical
# information (fish it out of data/).
#
# Requirements:
# - scc
# - hyperfine
# - gnuplot
#
# You must also have two binaries 'futhark-master' and
# 'futhark-automap' in your PATH, and two clones of the appropriate
# futhark-benchmarks branches:
#
# $ git clone  -b master git@github.com:diku-dk/futhark-benchmarks.git futhark-benchmarks-master
#
# $ git clone  -b automap git@github.com:diku-dk/futhark-benchmarks.git futhark-benchmarks-automap

set -e

# Directory containing unmodified benchmarks.
master=futhark-benchmarks-master
# Directory containing AUTOMAPed benchmarks.
automap=futhark-benchmarks-automap

# Unmodified compiler
futhark_master=futhark-master
# AUTOMAP compiler
futhark_automap=futhark-automap

programs() {
    ls $1/accelerate/*/*.fut \
       $1/finpar/*.fut \
       $1/rodinia/*/*.fut \
       $1/pbbs/*/*.fut \
       $1/parboil/*/*.fut \
       | grep -v -e -gui.fut
}

programs_master=$(programs "$master")
programs_automap=$(programs "$automap")
programs_nodir=$(echo $programs_master | sed s,$master/,,g)

# Get the non-source non-blank line count, using scc(1).
lines() {
    scc -f csv --no-cocomo --no-complexity "$@" | tail -n 2 | head -n 1 | cut -d, -f2
}

report_lines() {
    num_programs=$(echo $programs_master | wc -w)
    sloc_master=$(lines $programs_master)
    sloc_automap=$(lines $programs_automap)

    echo
    echo "# Lines of code"
    echo "Number of programs: $num_programs"
    echo "SLOC (original): $sloc_master"
    echo "SLOC (AUTOMAP):  $sloc_automap"
}

maps_out=data/maps.txt
report_maps() {
    rm -f $maps_out
    echo
    echo "# Change in number in maps after utilising AUTOMAP"
    total_maps_master=0
    total_maps_automap=0
    for p in $programs_nodir; do
        printf "%-60s " "$p"
        maps_master=$(cat "$master/$p" | grep -E '\bmap[1-9]?\W' -o | wc -l)
        maps_automap=$(cat "$automap/$p" | grep -E '\bmap[1-9]?\W' -o | wc -l)
        printf "%2d => %2d\n" "$maps_master" "$maps_automap"
        total_maps_master=$(($total_maps_master+$maps_master))
        total_maps_automap=$(($total_maps_automap+$maps_automap))
        echo "$p $total_maps_master $total_maps_automap" >> $maps_out
    done
    echo
    printf "Total change in maps: %3d => %3d\n" $total_maps_master $total_maps_automap
}

checktime() {
    hyperfine "$1 check $2" --export-csv /dev/stdout --style=none 2>/dev/null \
        | tail -n 1 \
        | cut -d, -f2
}

tctime_out=data/tctime.txt
report_tctime() {
    rm -f $tctime_out
    echo
    echo "# Type checking overhead"
    for p in $programs_nodir; do
        printf "%-60s " "$p"
        time_master=$(checktime "$futhark_master" "$master/$p")
        time_automap=$(checktime "$futhark_automap" "$automap/$p")
        if [ "$time_master" -a "$time_automap" ]; then
            slowdown=$(echo "scale=2; $time_automap / $time_master" | bc)
            printf "%.2fx\n" "$slowdown"
            echo "$p $time_master $time_automap" >> $tctime_out
        else
            printf "did not type check\n"
        fi
    done

    echo
    awk 'BEGIN{x}{x+=$3/$2}END{print "Mean slowdown:", x/FNR}' < $tctime_out
}

report_ilps() {
    rm -rf ilps && mkdir -p ilps
    echo
    echo "# Extracting ILPs"
    for p in $programs_nodir; do
        printf "%-60s " "$p"
        mkdir -p $(dirname data/ilps/$p)
        if ! FUTHARK_COMPILER_DEBUGGING=3 "$futhark_automap" check "$automap/$p" 2> data/ilps/$p.log; then
            printf "Failed\n"
        else
            awk -f findilps.awk < data/ilps/$p.log > data/ilps/$p.ilps
            k=$(cat data/ilps/$p.ilps | awk 'BEGIN{max=0}{if (int($2) > max){max=int($2)}}END{print max}')
            printf "Largest ILP: $k\n"
        fi
    done
}

analyse_ilps() {
    for p in $programs_nodir; do
        cat data/ilps/$p.ilps
    done | sort | uniq | sort --key=2 --numeric > data/ilptable

    awk '{print $2}' <data/ilptable >data/ilpsizes

    gnuplot ilps.gnu
}

mkdir -p data
mkdir -p reports

# Comment out the reports you are not interested in.

report_lines | tee reports/lines.txt
report_maps | tee reports/maps.txt
report_tctime | tee reports/tctime.txt
report_ilps | tee reports/ilps.txt
analyse_ilps
