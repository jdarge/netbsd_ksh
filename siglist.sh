#!/bin/bash
#
# Script to generate a sorted, complete list of signals on Linux
# suitable for inclusion in trap.c as array initializer.

set -e

: ${AWK:=awk}
: ${SED:=sed}

in=tmpi$$.c
out=tmpo$$.c
ecode=1
trapsigs='0 1 2 13 15'
trap 'rm -f $in $out; trap 0; exit $ecode' $trapsigs

CPP="${1-gcc -E}"

# The trap here to make up for a bug in bash (1.14.3(1)) that calls the trap
(
  trap $trapsigs
  echo '#include <signal.h>'
  echo ' { QwErTy /* dummy for sed sillies */ },'
  ${SED} -e '/^[[:space:]]*#/d' -e 's/^[[:space:]]*\([^[:space:]]\+\)[[:space:]][[:space:]]*\([^[:space:]]\+[[:space:]]*\)[[:space:]]*$/#ifdef \1\
   { QwErTy .signal = \1 , .name = "\1", .mess = "\2" },\
#endif/'
) >$in
echo '	{ QwErTy .signal = SIGNALS , .name = "DUMMY", .mess = "hook to expand array to total signals" },' >>$in
# work around for gcc > 5
$CPP $in | grep -v '^#' | tr -d '\n' | ${SED} 's/},/},\
/g' >$out
${SED} -n 's/{ QwErTy/{/p' <$out | ${AWK} '{print NR, $0}' | sort -k 5n -k 1n |
  ${SED} -E -e 's/^[0-9]* *//' -e 's/ +/ /' |
  ${AWK} 'BEGIN { last=0; }
	{
	    if ($4 ~ /^[0-9][0-9]*$/ && $5 == ",") {
		n = $4;
		if (n > 0 && n != last) {
		    while (++last < n) {
			printf "\t{ .signal = %d , .name = NULL, .mess = \"Signal %d\" } ,\n", last, last;
		    }
		    print;
		}
	    }
	}' |
  grep -v '"DUMMY"'
ecode=0

