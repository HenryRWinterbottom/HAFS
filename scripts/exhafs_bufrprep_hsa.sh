#!/bin/bash

################################################################################
#### UNIX Script Documentation Block
##
## Script name:         exhafs_bufrprep_hsa.sh
##
## Script description:  Create BUFR-formatted file for NOAA/AOML/HRD TEMP-DROP
##                      observations.
##
## Author:              Henry R. Winterbottom 
##
## Date:                2019-03-21
##
## Abstract:            This script generates a Binary Universal Format 
##                      (BUFR) file containing the NOAA/AOML/HRD dropsondes and 
##                      drift calculations to be appended to the 
##                      data-assimilation PREPBUFR files.
##
## Script history log:  
##
## 2019-03-21  Henry R. Winterbottom -- Original version.
##
## Usage: exhafs_bufrprep_hsa.sh
##
##   Imported Shell Variables:
##
##     BUFRPREPdir:      The top-level working directory for all BUFRPREP 
##                       applications.
##
##     COMROOT:          The experiment top-level COM directory location.
##
##     CYCLE:            The forecast cycle; formatted as %Y%m%d%H.
##
##     FCSTtype:         The forecast type; either 'history' or 'realtime'; this
##                       determines whether observations are collected from a
##                       GNU-zipped tarball (history) or parsed from composite
##                       sonde-type observation files (realtime).
##
##     HSAdatapath:      The user configuration-specified TEMP-DROP observation
##                       files and/or archive location.
##
##     ITRCROOT:         The experiment top-level INTERCOM directory location.
##
##     USER:             The host machine user login name.
##
##     SCRIPTdir:        The top-level script directory location; set by 
##                       jobs/JHAFS_ENVIR.
##
##     WORKdir:          The user configuration-specified top-level experiment 
##                       working directory.
##
##   NOTE: All imported shell variables should be sourced from the
##   environment defined for the respective experiment.
##
##   Exported Shell Variables:
##
##     ANALDATE:         The forecast cycle relative to which the observations 
##                       are to be formatted within the PREPBUFR file.
##
##     BUFR_TBLPATH:     The path to the PREPBUFR table for the TEMP-DROP sonde
##                       observations.
##
##     HSA_INTRP_OBSERR: A logical variable specifying whether to interpolate
##                       the observation error profile.
##
##     HSA_OBS_FILEPATH: The path to the ascii-formatted file list containing 
##                       the observations to be formatted within the PREPBUFR 
##                       file.
##
##     HSA_OBSERR_FILEPATH: The path to the ascii-formatted TEMP-DROP observation 
##                          errors file.
##
##     IS_HSA:           A logical variable specifying that the OBS-TO-BUFR 
##                       software is to be applied for TEMP-DROP sonde
##                       observations.
##
##     RUNPATH:          The directory within which the OBS-TO-BUFR software is
##                       to be run; typically within the working directory 
##                       (e.g., BUFRPREPdir).
##
##   Modules and files referenced:
##
##     scripts: ${SCRIPTdir}/exfv3sar_bufrprep_obstobufr.sh
##
## Remarks:
##
##   Condition codes:
##
##      0 - no problem encountered
##     >0 - some problem encountered
##
## Attributes:
##
##   Language: POSIX shell
##   Machine: IBM SP
##
################################################################################

set -x -e

# Define environment for respective experiment.

. ${WORKdir}/${CYCLE}/intercom/experiment.${CYCLE}

#----

# FUNCTION:

# create_tempdrop_sonde_namelist.sh

# DESCRIPTION:

# This function creates the namelist file tempdrop-sonde.input in the
# working directory.

create_tempdrop_sonde_namelist (){

    # Create namelist file tempdrop-sonde.input in working directory.

    cat << EOF > ${BUFRPREPdir}/tempdrop/tempdrop-sonde.input
&share
datapath        = '${BUFRPREPdir}/tempdrop/'
sonde_filelist  = '${BUFRPREPdir}/tempdrop/sonde.filelist'
write_hsa       = T
write_hsa_drift = T
write_nc_skewt  = T
/
EOF
}

#----

# FUNCTION:

# deliver_products.sh

# DESCRIPTION:

# This function copies (e.g., delivers) the relavant files to
# respective paths expected by the workflow.

deliver_products (){

    # Create directories to which to deliver products.

    mkdir -p ${COMROOT}/bufrprep
    mkdir -p ${ITRCROOT}/bufrprep

    # Copy (e.g., deliver) relevant file to respective paths.

    cp ${BUFRPREPdir}/tempdrop/prepbufr.hsa ${COMROOT}/bufrprep
    cp ${BUFRPREPdir}/tempdrop/prepbufr.hsa ${ITRCROOT}/bufrprep
}

#----

# FUNCTION:

# dump_tempdrop_history.sh

# DESCRIPTION:

# This function dumps the contents of a tarball file containing
# available TEMP-DROP formatted observation files.

dump_tempdrop_history (){
    
    # Define list of available tarball files; it is assumed that in
    # history (or retrospective) mode the observation files are
    # archived within a tarball file.

    filenames=`ls ${HSAdatapath} | grep ${CYCLE}`
    for filename in ${filenames}; do

	# Copy tarball to working directory.
	
	cp ${HSAdatapath}/${filename} .

	# Unpack tarball in working directory.

	tar -xvf ${filename}

	# Remove tarball within working directory

	rm ${filename} 2> /dev/null || :

    done # for filename in ${filenames}
}

#----

# FUNCTION:

# dump_tempdrop_sonde.sh

# DESCRIPTION:

# This function collects the available observations in accordance with
# the user forecast configuration.

dump_tempdrop_sonde (){

    # Create working directory for the TEMP-DROP formatted
    # observations.
    
    mkdir -p ${BUFRPREPdir}/tempdrop/obs

    # Move to the working directory for the TEMP-DROP formatted
    # observations.

    cd ${BUFRPREPdir}/tempdrop/obs

    # If running in history (or retrospective) mode, proceed
    # accordingly; otherwise, assume that forecast is running in
    # forecast (or real-time) mode and obtain the available files (if
    # any) accordingly.

    if [ ${FCSTtype} == 'history' ]; then
	dump_tempdrop_history
    else # if [ ${FCSTtype} == 'history' ]
	dump_tempdrop_realtime
    fi   # if [ ${FCSTtype} == 'history' ]
}

#----

# FUNCTION:

# format_tempdrop_sonde.sh

# DESCRIPTION:

# This function prepares the TEMP-DROP sonde formatted files by
# stripping any meta-characters and arranging the observation time
# information accordingly.

format_tempdrop_sonde (){

    # Create a list of observation files

    filenames=`ls ${BUFRPREPdir}/tempdrop/obs`

    # Remove any previous occurrances of external file list.

    rm sonde.filelist 2> /dev/null || :

    # Loop through all file names and check for data non-usage flags.

    for filename in ${filenames}; do

	# Check for strings in file contents; if the check is
	# unsuccessful (e.g., returns '0'), process the file.

	if egrep -q "COMM CHECK|TTAA|TTBB" ${BUFRPREPdir}/tempdrop/obs/${filename}; then

	    # Remove observation file.

            rm ${BUFRPREPdir}/tempdrop/obs/${filename} 2> /dev/null || :

	else # if egrep -q "COMM CHECK|TTAA|TTBB" 
	     # ${BUFRPREPdir}/tempdrop/obs/${filename}

	    # Create new file which will contain any modifications
	    # made to the original observation file.

	    cp ${BUFRPREPdir}/tempdrop/obs/${filename} ${BUFRPREPdir}/tempdrop/${filename}.mod

	    # Remove all meta-characters from strings in file; this
	    # step is necessary as some of the archived files may have
	    # been generated on a non-UNIX platform.	    

            strip_meta ${BUFRPREPdir}/tempdrop/${filename}.mod

	    # Define strings within file to seek out.

	    srchstrs=( 'REL SPG SPL' )

	    # Loop through search strings and proceed accordingly.

	    for srchstr in ${srchstrs}; do

		# Format observation time information for respective
		# sonde.

		prepend_string_newline ${BUFRPREPdir}/tempdrop/${filename}.mod ${srchstr}

	    done # for srchstr in ${srchstrs}

	    # Append file name to list of files to be processed.

	    echo "'${BUFRPREPdir}/tempdrop/${filename}.mod'" >> ${BUFRPREPdir}/tempdrop/sonde.filelist
		     
	fi   # if egrep -q "COMM CHECK|TTAA|TTBB" 
             # ${BUFRPREPdir}/tempdrop/obs/${filename}

    done # for filename in ${filenames}
}

#----

# FUNCTION:

# prepend_string_newline.sh

# DESCRIPTION:

# This function pre-pends a user specified string with a new line
# followed by the line containing the respective string; for example:

# > input line: we are searching for foobar

# > search string: foobar

# > output line: we are searching for 
#                foobar

# INPUT VARIABLES:

#  * infile; the path to the file possibly containing search strings.

#  * string; the string to pre-pended with a new line.

prepend_string_newline (){

    # Get filename name from user arguments.

    infile=$1

    # Get string to replace from user arguments.

    string=$2

    # Replace any matching strings, in place, with a new line and the
    # respective matching string.

    perl -pe "s/${string}/\n${string}/g" < ${infile} > tmp.file

    # Replace original file with updated file.

    mv tmp.file ${infile}
}

#----

# FUNCTION:

# run_obs_to_bufr.sh

# DESCRIPTION:

# This function launches the executable to format the TEMP-DROP sonde
# observations within a PREPBUFR-formatted file.

run_obs_to_bufr (){

    # Define external file to contain forecast cycle date and time
    # information.

    export TIMEINFO_FILEPATH=${ITRCROOT}/cycle.timeinfo

    # Define analysis date relative to which to define observation
    # times.

    analdate=`cat ${TIMEINFO_FILEPATH} | grep 'date_string' | awk '{print $2}'`

    # Define environment variables.

    export ANALDATE=${analdate}
    export RUNPATH=${BUFRPREPdir}/tempdrop
    export IS_HSA=T
    export BUFR_TBLPATH=${HSAprepbufrtbl_filepath}
    export HSA_BUFR_INFO_FILEPATH=${HSAbufrinfo_filepath}
    export HSA_INTRP_OBSERR=T
    export HSA_OBS_FILEPATH=${BUFRPREPdir}/tempdrop/obs_to_bufr.filelist
    export HSA_OBSERR_FILEPATH=${HSAobserr_filepath}

    # Create PREPBUFR-formatted file for TEMP-DROP sonde observations.

    ${SCRIPTdir}/exhafs_bufrprep_obstobufr.sh
}

#----

# FUNCTION:

# run_tempdrop_sonde.sh

# DESCRIPTION:

# This function launches the executable to format the TEMP-DROP
# formatted sonde files and creates an external file containing those
# files to be appended to the PREPBUFR-formatted file.

run_tempdrop_sonde (){
    
    # Move to working directory.

    cd ${BUFRPREPdir}/tempdrop

    # Copy executable to local (e.g., working) directory.

    cp ${tds_exe} ${BUFRPREPdir}/tempdrop/tds.x

    # Define unique standard output file.

    pgmout=${BUFRPREPdir}/tempdrop/tempdrop_sonde.out.${pid}

    # Launch executable and write standard output to external file.

    ${BUFRPREPdir}/tempdrop/tds.x > ${pgmout}

    # Find all observation files to be used for PREPBUFR creation in
    # working directory.

    filenames=`ls ${BUFRPREPdir}/tempdrop | grep drft`

    # Remove previous occurances of external file list.

    rm ${BUFRPREPdir}/tempdrop/obs_to_bufr.filelist 2> /dev/null || :

    # Loop through each observation file and append file path to
    # external file.

    for filename in ${filenames}; do

	# Write file path to external file.

	echo "'${BUFRPREPdir}/tempdrop/${filename}'" >> ${BUFRPREPdir}/tempdrop/obs_to_bufr.filelist

    done # for filename in ${filenames}
}

#----

# FUNCTION:

# strip_meta.sh

# DESCRIPTION:

# This function strips meta-characters (including carriage returns)
# from the user specified input file, while preserving the end-of-line
# designations; this function replaces the user specified file with a
# file that is free of meta-characters and carriage returns.

# INPUT VARIABLES:

#  * infile; the path to the file possible containing meta-characters
#    and carriage returns.

strip_meta (){

    # Get filename name from user arguments.

    infile=$1

    # Remove any meta-characters, including carriage returns from
    # file; preserve the end-line designations.

    cat ${infile} | tr -dc '[:print:]\n' > tmp.file

    # Replace original file with meta-character free file.

    mv tmp.file ${infile}
}

#----

script_name=`basename "$0"`
start_date=`date`
echo "START ${script_name}: ${start_date}"

# The following tasks are accomplished by this script:

# (1) Create local sub-directories.

export BUFRPREPdir=${EXPTROOT}/bufrprep

# (2) The available TEMP-DROP formatted sonde observations are
#     collected relative to the forecast configuration (e.g., HISTORY
#     versus REALTIME).

dump_tempdrop_sonde 

# (3) The available TEMP-DROP formatted sonde observations are
#     formatted such that any meta-characters and time-stamp (e.g.,
#     launch and landing/splash) are properly formatted.

format_tempdrop_sonde

# (4) Create the appropriate namelist and external files required to
#     estimate the sonde drift.

create_tempdrop_sonde_namelist

# (5) Compute the sonde drift and prepare files for the PREPBUFR file.

run_tempdrop_sonde

# (6) Create the PREPBUFR formatted file containing the TEMP-DROP
#     sonde observations (including the estimated drift).

run_obs_to_bufr

# (7) Deliver the relevant files to the respective /intercom and /com
#     paths.

deliver_products

export ERR=$?
export err=${ERR}
stop_date=`date`
echo "STOP ${script_name}: ${stop_date}"

exit ${err}
