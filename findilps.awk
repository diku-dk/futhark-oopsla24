# Run this on the stderr of
#
#  $ FUTHARK_COMPILER_DEBUGGING=3 futhark check foo.fut
#
# to identify the length of ILP programs (by count of constraints)
# arising during type check of foo.fut.

/^# function / { f=$3; }
/^$/ && ilp { printf "%40s %7d\n", f, len; ilp=0; }
/solveRankILP/ { ilp=1; len=-4; prog=""; } # Start count at negative
                                           # to account for header.
ilp { prog = prog "\n" $0; len++; }
