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
# You must also have two binaries 'futhark-original' and
# 'futhark-automap' in your PATH, and two clones of the appropriate
# futhark-benchmarks branches:
#
# $ git clone  -b master git@github.com:diku-dk/futhark-benchmarks.git futhark-benchmarks-original
#
# $ git clone  -b automap git@github.com:diku-dk/futhark-benchmarks.git futhark-benchmarks-automap

set -e

# Directory containing unmodified benchmarks.
master=futhark-benchmarks-original
# Directory containing AUTOMAPed benchmarks.
automap=futhark-benchmarks-automap

# Original compiler
futhark_master=futhark-original
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

report_maps() {
    rm -f data/maps.txt
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
        echo "$p $total_maps_master $total_maps_automap" >> data/maps.txt
    done
    echo
    printf "Total change in maps: %3d => %3d\n" $total_maps_master $total_maps_automap
    echo -n "$total_maps_master" > "data/maps_original"
    echo -n "$total_maps_automap" > "data/maps_automap"
}

checktime() {
    hyperfine "$1 check $2" --export-csv /dev/stdout --style=none 2>/dev/null \
        | tail -n 1 \
        | cut -d, -f2
}

report_tctime() {
    rm -f data/tctime.txt
    echo
    echo "# Type checking overhead"
    for p in $programs_nodir; do
        printf "%-60s " "$p"
        time_master=$(checktime "$futhark_master" "$master/$p")
        time_automap=$(checktime "$futhark_automap" "$automap/$p")
        if [ "$time_master" -a "$time_automap" ]; then
            slowdown=$(echo "scale=2; $time_automap / $time_master" | bc)
            printf "%.2fx\n" "$slowdown"
            echo "$p $time_master $time_automap" >> data/tctime.txt
        else
            printf "did not type check\n"
        fi
    done

    echo
    awk 'BEGIN{x}{x+=$3/$2}END{printf "%.2f",x/FNR}' < data/tctime.txt > data/mean_slowdown
    printf "Mean slowdown: $(cat data/mean_slowdown)\n"
}

report_ilps() {
    echo
    echo "# Extracting ILPs"
    largest=0
    for p in $programs_nodir; do
        printf "%-60s " "$p"
        mkdir -p $(dirname data/ilps/$p)
        if ! FUTHARK_COMPILER_DEBUGGING=3 "$futhark_automap" check "$automap/$p" 2> data/ilps/$p.log; then
            printf "Failed\n"
        else
            awk -f findilps.awk < data/ilps/$p.log > data/ilps/$p.ilps
            k=$(awk 'BEGIN{max=0}{if (int($2) > max){max=int($2)}}END{print max}' < data/ilps/$p.ilps)
            printf "Largest ILP: $k\n"
            if [ "$k" -gt "$largest" ]; then
                largest=$k
            fi
        fi
    done
    echo -n "$largest" > data/largest_ilp
    for p in $programs_nodir; do
        cat data/ilps/$p.ilps | awk '{print $2}'
    done > data/ilp_sizes
    num_ilps=$(wc -l data/ilp_sizes | cut -d' ' -f1)
    cat data/ilp_sizes | sort -n | head -n"$((num_ilps/2))" | tail -n1 > data/median_ilp
    awk 'BEGIN{x}{x+=$1}END{printf "%d",x/FNR}' < data/ilp_sizes > data/mean_ilp
}

analyse_ilps() {
    for p in $programs_nodir; do
        cat data/ilps/$p.ilps
    done | sort | uniq | sort --key=2 --numeric > data/ilptable

    awk '{print $2}' <data/ilptable >data/ilpsizes

    echo
    echo "# Fig. 12"
    gnuplot -e 'set terminal dumb' ilps.gnu
    gnuplot -e 'set terminal pdf size 4,2' -e 'set output "reports/fig12.pdf"' ilps.gnu

}

fig13() {
    num_programs=$(echo $programs_master | wc -w)
    sloc_master=$(lines $programs_master)
    sloc_automap=$(lines $programs_automap)
    maps_original=$(cat data/maps_original)
    maps_automap=$(cat data/maps_automap)
    largest_ilp=$(cat data/largest_ilp)
    median_ilp=$(cat data/median_ilp)
    mean_ilp=$(cat data/mean_ilp)
    mean_slowdown=$(cat data/mean_slowdown)

    echo
    echo "# Fig. 13"
    printf "Number of programs:          %5d\n" "${num_programs}"
    printf "Change in lines of code:     %5d => %5d\n" "${sloc_master}" "${sloc_automap}"
    printf "Change in maps:              %5d => %5d\n" "${maps_original}" "${maps_original}"
    printf "Largest ILP size:            %5d constraints\n" "${largest_ilp}"
    printf "Median ILP size:             %5d constraints\n" "$median_ilp"
    printf "Mean ILP size:               %5d constraints\n" "$mean_ilp"
    printf "Mean type checking slowdown: %3.2f\n" "$mean_slowdown"
}

mkdir -p data
mkdir -p reports

report_lines | tee reports/lines.txt
report_maps | tee reports/maps.txt
report_tctime | tee reports/tctime.txt
report_ilps | tee reports/ilps.txt
analyse_ilps | tee reports/fig12.txt
fig13 | tee reports/fig13.txt
