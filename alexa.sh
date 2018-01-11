#!/bin/sh

# Downloads and parses the top 50 list from alexa
# to a single file containing only the top domain URLs

# Then performs a traceroute for each of those domains
# logging the results to individual files

usage() {
	echo usage: `basename $0` '[-gzip] [-listfile filename] [-j <n>] runname' 1>&2
	echo '  -gzip:     compress run folder into .gzip file after done' 1>&2
	echo '  -listfile: provide your own list of domains to perform traceroute to' 1>&2
	echo '  -j <n>:    number of parallell traceroute operations launched simultaneously' 1>&2
	echo '  runname:   folder name where all output files will be stored'
	exit 1
}

errquit() {
	echo `basename $0`: ERROR: $1 1>&2
	[ $# -gt 1 ] && usage
	exit 1
}

runlog() {
	echo $1 >> $logfile
	[ $# -gt 1 ] && echo $1
}

# Check that there are arguments, otherwise something is wrong
[ $# -lt 1 ] && errquit "Wrong number of arguments" true

# Set default assumptions on script execution
compress=NO       # Create a gzip file from folder after execution
fetchalexa=YES	  # Fetch the alexa top 50 list, disabled if a list file is provided
parallell_reset=4 # Number of paralell traceroutes launched simulatneously
key="$1"          # If only one argument, store runid as key for later

# Handle script arguments
while [[ $# -gt 0 ]]
do
	key="$1"

	case $key in
		-gzip)
		compress=YES
		shift
		;;
		-listfile)
		listfile="$2"
		fetchalexa=NO
		shift
		shift
		;;
		-j)
		parallell_reset="$2"
		shift
		shift
		*) # Unknown option, should only be the rundir
		shift
		;;
	esac
done

# Rundir needs to be last parameter
rundir=$key
logfile="$rundir/run.log"
# If no listfile provided, default to alexa.sitelist that is to be fetched
[ -z ${listfile=$rundir/alexa.sitelist} ]
sitelist=$listfile

# Output parsed input parameters
echo Compress = $compress
echo Fetch Alexa = $fetchalexa
echo Rundir = $rundir
echo Logfile = $logfile
echo Sitelist = $sitelist

[ -e $rundir ] && errquit "There exists a run with the name already"

mkdir $rundir
touch logfile
runlog "Created run directory" true
runlog "Time of run: `date`" true

[ $fetchalexa == "YES" ] && curl --url https://www.alexa.com/topsites | grep "href=\"/siteinfo/" | sed 's/<a href="\/siteinfo\/\(.*\)">.*/\1/g' > $sitelist

# Additional arguments:
#	-a for AS# resolution
# 	-w 2 for shorter than default (5) timeout

parallell_runs=0

while read u; do
	runlog "`date` - Tracerouting $u" true
	traceroute -a -w 2 $u > $rundir/$u.trace 2>&1 &
	[ $parallell_runs -eq 0 ] && parallell_runs=$parallell_reset
	let "parallell_runs -= 1"
	[ $parallell_runs -eq 0 ] && wait
done <$sitelist

[ $parallell_runs -ne 0 ] && wait

