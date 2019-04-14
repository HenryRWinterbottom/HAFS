#!/bin/ksh

################################################################################
#### UNIX Script Documentation Block
##
## Script name:         exhafs_bufrprep_obstobufr.sh
##
## Script description:  Creates PREPBUFR-formatted observation files.
##
## Author:              Henry R. Winterbottom 
##
## Date:                2019-03-26
##
## Abstract:            This script generates a Binary Universal Format
##                      (BUFR) file in accordance with the user
##                      environment variables.
##
## Script history log:  
##
## 2019-03-26  Henry Winterbottom -- Original version.
##
## Usage: exhafs_bufrprep_obstobufr.sh
##
##   Imported Shell Variables:
##
##     ANALDATE:         The forecast cycle relative to which the observations 
##                       are to be formatted within the PREPBUFR file.
##
##     BUFR_TBLPATH:     The path to the PREPBUFR table for the TEMP-DROP sonde
##                       observations.
##
##     CYCLE:            The forecast cycle; formatted as %Y%m%d%H.
##
##     EXPTROOT:         The user configuration-specified top-level experiment 
##                       working directory.
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
##     IS_GIVTDRUV:      A logical variable specifying that the OBS-TO-BUFR 
##                       software is to be applied for GIV-TDR u- and v-wind
##                       observations.
##
##     IS_HSA:           A logical variable specifying that the OBS-TO-BUFR 
##                       software is to be applied for TEMP-DROP sonde
##                       observations.
##
##     RUNPATH:          The directory within which the OBS-TO-BUFR software is
##                       to be run; typically within the working directory 
##                       (e.g., BUFRPREPdir).
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

# create_obs_to_bufr_namelist.sh

# DESCRIPTION:

# This function creates the namelist file obs-to-bufr.input in the
# user-specified working directory.

create_obs_to_bufr_namelist (){

    # Define default values for all namelist variables in SHARE block.

    runpath=${RUNPATH:-'./'}
    datapath=${DATAPATH:-'./'}
    is_fcstmdl=${IS_FCSTMDL:-F}
    is_givtdruv=${IS_GIVTDRUV:-F}
    is_hsa=${IS_HSA:-F}
    is_nhcgtcm=${IS_NHCGTCM:-F}
    is_tcm=${IS_TCM:-F}
    obs_flag=${OBS_FLAG:-F}

    # Define default values for all namelist variables in BUFR block.

    bufr_tblpath=${BUFR_TBLPATH:-'NOT USED'}

    # Define default values for all namelist variables in FCSTMDL
    # block.

    fcst_model_bufr_info_filepath=${FCST_MODEL_BUFR_INFO_FILEPATH:-'NOT USED'}
    fcst_model_filepath=${FCST_MODEL_FILEPATH:-'NOT USED'}

    # Define default values for all namelist variables in FLAG block.

    obs_flag_json_vtable=${OBS_FLAG_JSON_VTABLE:-'NOT USED'}

    # Define default values for all namelist variables in GIVTDRUV
    # block.

    givtdruv_bufr_info_filepath=${GIVTDRUV_BUFR_INFO_FILEPATH:-'NOT USED'}
    givtdruv_obs_filepath=${GIVTDRUV_OBS_FILEPATH:-'NOT USED'}

    # Define default values for namelist variables in HSA block.

    hsa_bufr_info_filepath=${HSA_BUFR_INFO_FILEPATH:-'NOT USED'}
    hsa_intrp_obserr=${HSA_INTRP_OBSERR:-F}
    hsa_obs_filepath=${HSA_OBS_FILEPATH:-'NOT USED'}
    hsa_obserr_filepath=${HSA_OBSERR_FILEPATH:-'NOT USED'}

    # Define default values for namelist variables in NHCGTCM block.

    nhcgtcm_bufr_info_filepath=${NHCGTCM_BUFR_INFO_FILEPATH:-'NOT USED'}
    nhcgtcm_obs_filepath=${NHCGTCM_OBS_FILEPATH:-'NOT USED'}

    # Define default values for namelist variables in TCM block.

    tcm_bufr_info_filepath=${TCM_BUFR_INFO_FILEPATH:-'NOT USED'}
    tcm_obs_filepath=${TCM_OBS_FILEPATH:-'NOT USED'}

    # Define default values for namelist variables in TOPO block.

    is_temis=${IS_TEMIS:-F}
    topo_filepath=${TOPO_FILEPATH:-'NOT USED'}
    mask_land=${MASK_LAND:-F}

    # Create namelist file obs-to-bufr.input in user-specified working
    # directory.

    cat << EOF > ${runpath}/obs-to-bufr.input
&share
analdate    = '${ANALDATE}'
datapath    = '${datapath}'
is_fcstmdl  = ${is_fcstmdl}
is_givtdruv = ${is_givtdruv}
is_hsa      = ${is_hsa}
is_nhcgtcm  = ${is_nhcgtcm}
is_tcm      = ${is_tcm}
obs_flag    = ${obs_flag}
/

&bufr
bufr_tblpath = '${bufr_tblpath}'
/

&fcstmdl
fcst_model_bufr_info_filepath = '${fcst_model_bufr_info_filepath}'
fcst_model_filepath           = '${fcst_model_filepath}'
/

&flag
obs_flag_json_vtable = '${obs_flag_json_vtable}'
/

&givtdruv
givtdruv_bufr_info_filepath = '${givtdruv_bufr_info_filepath}'
givtdruv_obs_filepath       = '${givtdruv_obs_filepath}'
/

&hsa
hsa_bufr_info_filepath = '${hsa_bufr_info_filepath}'
hsa_intrp_obserr       = ${hsa_intrp_obserr}
hsa_obs_filepath       = '${hsa_obs_filepath}'
hsa_obserr_filepath    = '${hsa_obserr_filepath}'
/

&nhcgtcm
nhcgtcm_bufr_info_filepath = '${nhcgtcm_bufr_info_filepath}'
nhcgtcm_obs_filepath       = '${nhcgtcm_obs_filepath}'
/

&tcm
tcm_bufr_info_filepath = '${tcm_bufr_info_filepath}'
tcm_obs_filepath       = '${tcm_obs_filepath}'
/

&topo
is_temis      = ${is_temis}
topo_filepath = '${topo_filepath}'
mask_land     = ${mask_land}
/ 
EOF
}

#----

# FUNCTION:

# run_obs_to_bufr.sh

# DESCRIPTION:

# This function launches the executable to format the user specified
# observations within a PREPBUFR-formatted file.

run_obs_to_bufr (){

    # Define default values for all namelist variables in SHARE block.

    runpath=${RUNPATH:-'./'}

    # Move to working directory.

    cd ${runpath}

    # Copy executable to local (e.g., working) directory.

    cp ${otb_exe} ${runpath}/otb.x

    # Define unique standard output file.

    pgmout=${runpath}/obs_to_bufr.out.${pid}

    # Launch executable and write standard output to external file.

    ${runpath}/otb.x > ${pgmout}
}

#----

script_name=`basename "$0"`
start_date=`date`
echo "START ${script_name}: ${start_date}"

. ${MODULES}

# The following tasks are accomplished by this script:

# (1) Create the appropriate namelist and external files for the
#     creation of the PREPBUFR file.

create_obs_to_bufr_namelist

# (2) Create the PREPBUFR formatted file for the user specified
#     observations.

run_obs_to_bufr

export ERR=$?
export err=${ERR}
stop_date=`date`
echo "STOP ${script_name}: ${stop_date}"

exit ${err}


