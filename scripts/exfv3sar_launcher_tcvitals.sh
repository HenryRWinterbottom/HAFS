#!/bin/ksh

################################################################################
#
# UNIX Script Documentation Block
#
# Script name:         exfv3sar_launcher_tcvitals.sh
#
# Script description:  This script generates...
#
# Script history log:  2019-03-27  Henry Winterbottom -- Original version.
#
################################################################################

set -x -e

# Define environment for respective experiment.

. ${WORKdir}/${USER}/${EXPTname}/${CYCLE}/intercom/experiment.${CYCLE}

#----

# FUNCTION:

# parse_tcv_records.sh

# DESCRIPTION:

# This function collects TC-vitals records in accordance with the user
# experiment configuration.

parse_tcv_records (){

    # Define external file to contain TC-vitals records for events in
    # accordance with the user experiment configuration.

    export TCV_RECORD_FILEPATH=${ITRCROOT}/tcvitals.${CYCLE}

    # Remove previous occurance of external file.

    rm ${TCV_RECORD_FILEPATH} 2> /dev/null || :

    # Check local variable and proceed accordingly

    if [ ${TCEVENT}=='NONE' ]; then

	# Parse TC-vitals records relative to the user specified
	# forecast cycle only.

	parse_tcv_records_cycle

#    elif # if [ ${TCEVENT}=='NONE' ]

	# DO NOTHING, YET!

    fi   # if [ ${TCEVENT}=='NONE' ]
}

#----

# FUNCTION:

# tcv_record_cycle.sh

# DESCRIPTION:

# This function collects the TC-vitals record for the user specified
# TC event for the current forecast cycle.

# INPUT VARIABLES:

# * tcv_event; the TC event for which to collect the TC-vitals record
#   for the current forecast cycle.

tcv_record_cycle (){

    # Get TC event from user arguments.

    tcv_event=$1

    # Capture the most inclusive information for the current TC
    # event for the current cycle and append it to the external
    # file.
    
    cat ${SYNDATpath}/* | grep -w "${TCV_TIMESTAMP}" | grep -w ${tcv_event} | sort -nr | head -1 >> ${TCV_RECORD_FILEPATH}
}

#----

# FUNCTION:

# tcv_record_history.sh

# DESCRIPTION:

# This function collects all previous TC-vitals records for the user
# specified TC event.

tcv_record_history (){

    # Loop through all TC events for current cycle and create a
    # composite TC-vitals history file for each event.
    
    while read -r tcv_event; do

	# Initialize local variable.
    
	tcv_check=9999

	# Define initial forecast cycle for TC event.
    
	cycle=`cat ${TIMEINFO_FILEPATH} | grep -w "cycle" | awk '{print $2}'`
    
	# Define history file for TC event TC-vitals records.
    
	history_file=${ITRCROOT}/tcvitals.${tcv_event}.${CYCLE}.history
    
	# Remove any previous occurances of external file.
    
	rm ${history_file} 2> /dev/null || :
    
	# Loop through all previous cycles until the respective TC
	# event can no longer be traced.

	while [ ${tcv_check} -ge 1 ]; do

	    # Define external file to contain previous cycle time and
	    # date information.

	    timeinfo_filepath=${LAUNCHERdir}/tcv_cycle.timeinfo

	    # Define previous cycle information relevant to current
	    # cycle.

	    python ${USHdir}/date_time_format.py --date_string ${cycle} --offset_seconds -${SYNDAToffset_seconds} --output_file ${timeinfo_filepath}

	    # Define previous forecast cycle time stamp attributes.

	    year=`cat ${timeinfo_filepath} | grep -w "year" | awk '{print $2}'`
	    month=`cat ${timeinfo_filepath} | grep -w "month" | awk '{print $2}'`
	    day=`cat ${timeinfo_filepath} | grep -w "day" | awk '{print $2}'`
	    hour=`cat ${timeinfo_filepath} | grep -w "hour" | awk '{print $2}'`
	    cycle=`cat ${timeinfo_filepath} | grep -w "cycle" | awk '{print $2}'`

	    # Remove previous occurances of external file.

	    rm ${timeinfo_filepath} 2> /dev/null || :

	    # Define time stamp search string for TC-vitals records.

	    tcv_timestamp="${year}${month}${day} ${hour}00"
	
	    # Check that the respective TC event has TC-vitals record
	    # for the previous forecast cycle.
	    
	    tcv_check=`cat ${SYNDATpath}/* | grep -w "${tcv_timestamp}" | grep -wc ${tcv_event}` || :

	    # Check local variable and proceed accordingly.

	    if [ ${tcv_check} -ge 1 ]; then
		
		# Capture the most inclusive information for the
		# current TC event for the respective previous
		# forecast cycle and append it to the external file.

		cat ${SYNDATpath}/* | grep -w "${tcv_timestamp}" | grep -w ${tcv_event} | sort -nr | head -1 >> ${history_file}

	    fi # if [ ${tcv_check} -ge 1 ]

	done # while [ ${tcv_check}>0 ]

	# Reorder file such that the oldest time stamp is first and
	# write to temporary file path.

	cat ${history_file} | sort -k 4,4 > ${LAUNCHERdir}/tmp.file

	# Rename temporary file path and replace respective TC event
	# history file path.

	mv ${LAUNCHERdir}/tmp.file ${history_file}

    done < ${TCV_EVENTS_FILEPATH}
}

#----

# FUNCTION:

# parse_tcv_records_cycle.sh

# DESCRIPTION:

# This function parses all files in the user specified path
# (SYNDATpath) and collects all TC-vitals records for the current
# forecast cycle and also create a log of all previous TC-vitals
# records for the respective events.

parse_tcv_records_cycle (){

    # Define file path to contain a list of the TC-vitals events for
    # the current forecast cycle.

    export TCV_EVENTS_FILEPATH=${ITRCROOT}/tcevents.${CYCLE}.info

    # Write all TC-vitals events for the current forecast cycle to an
    # external file.

    cat ${SYNDATpath}/* | grep -E "JTWC|NHC" | grep -w "${TCV_TIMESTAMP}" | awk '{print $2}' | sort -u > ${TCV_EVENTS_FILEPATH}

    # Loop through all TC events for current cycle and create a
    # composite TC-vitals file and TC-vitals history file for each
    # event.
    
    while read -r tcv_event; do

	# Collect TC-vitals records for respective TC event for the
	# current forecast cycle.

	tcv_record_cycle ${tcv_event}

    done < ${TCV_EVENTS_FILEPATH}

    # Create a TC-vitals records history files for the respective TC
    # events within the current forecast cycle.

    tcv_record_history
}

#----

script_name=`basename "$0"`
start_date=`date`
echo "START ${script_name}: ${start_date}"

# The following tasks are accomplished by this script:

# (1) Create local sub-directories.

export LAUNCHERdir=${EXPTROOT}

# (2) Parse the TC-vitals record and collect all information in
#     accordance with the user specified experiment configuration.

parse_tcv_records

stop_date=`date`
echo "STOP ${script_name}: ${stop_date}"

exit
