set print 'data/ilpstats'
set zeroaxis
set style data points
set key box top left
set logscale x 2
set xlabel 'Size of ILP problem'
set ylabel 'Fraction'
set key off

stats 'data/ilpsizes'
N = STATS_records

plot "" using 1:(1.) smooth cnormal notitle lw 2
