#!/bin/sh

# Downloads and parses the top 50 list from alexa
# to a single file containing only the top domain URLs

usage() {
	echo usage: `basename $0` 'runname' 1>&2
	exit 1
}

errquit() {
	echo `basename $0`: ERROR: $1 1>&2
	[ $# -gt 1 ] && usage
	exit 1
}

[ $# -lt 1 ] && errquit "Wrong number of arguments" true

[ -a $1 ] && errquit "There exists a run with the name already"

mkdir $1
curl --url https://www.alexa.com/topsites | grep "href=\"/siteinfo/" | sed 's/<a href="\/siteinfo\/\(.*\)">.*/\1/g' > $1/sitelist
