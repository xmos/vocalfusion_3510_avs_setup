#!/usr/bin/env bash
pushd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null
SETUP_DIR="$( pwd )"
RPI_SETUP_DIR=$SETUP_DIR/vocalfusion-rpi-setup

RPI_SETUP_TAG="v2.1.0"
AVS_DEVICE_SDK_TAG="xmos_v1.20.1"
AVS_SCRIPT="setup.sh"

# Valid values for XMOS device
VALID_XMOS_DEVICES="xvf3100 xvf3500 xvf3510"
XMOS_DEVICE=
VALID_XMOS_DEVICES_DISPLAY_STRING=
NUMBER_OF_VALID_DEVICES=$(echo $VALID_XMOS_DEVICES | wc -w)
i=1
SEP=
for d in $VALID_XMOS_DEVICES; do
  if [[ $i -eq $NUMBER_OF_VALID_DEVICES ]]; then
    SEP=" or "
  fi
  VALID_XMOS_DEVICES_DISPLAY_STRING=$VALID_XMOS_DEVICES_DISPLAY_STRING$SEP$d
  SEP=", "
  (( ++i ))
done

# Default device serial number if nothing is specified
DEVICE_SERIAL_NUMBER="123456"

usage() {
  echo  'usage: auto_install.sh [OPTIONS] DEVICE-TYPE'
  echo  'A JSON config file, config.json, must be present in the current working directory.'
  echo  'The config.json can be downloaded from developer portal and must contain the following:'
  echo  '   "clientId": "<Auth client ID>"'
  echo  '   "productId": "<your product name for device>"'
  echo  ''
  echo  'Optional parameters'
  echo  '  -s <serial-number>  If nothing is provided, the default device serial number is 123456'
  echo  '  -h                  Display this help and exit'
  echo  ''
  echo  'Required parameters'
  echo  '  DEVICE-TYPE         XMOS device to setup: '$VALID_XMOS_DEVICES_DISPLAY_STRING
}

CONFIG_JSON_FILE="config.json"
if [ ! -f "$CONFIG_JSON_FILE" ]; then
    echo "error: config JSON file not found."
    echo
    usage
    exit 1
fi

OPTIONS=s:x:h
while getopts "$OPTIONS" opt ; do
    case $opt in
        s )
            DEVICE_SERIAL_NUMBER="$OPTARG"
            ;;
        h )
            usage
            exit 1
            ;;
    esac
done

shift $(( OPTIND - 1 ))

if [[ $# -lt 1 ]]; then
  echo "error: no device type specified."
  echo
  usage
  exit 1
fi

XMOS_DEVICE=$1

# validate XMOS_DEVICE value
DEVICE_IS_VALID=
for d in $VALID_XMOS_DEVICES; do
  if [[ $d = $XMOS_DEVICE ]]; then
    DEVICE_IS_VALID=y
    break
  fi
done
if [[ -z "$DEVICE_IS_VALID" ]]; then
  echo "error: $XMOS_DEVICE is not a valid device type."
  echo
  usage
  exit 1
fi

# Exit if chromium browser is open
if pgrep chromium > /dev/null ; then
  echo "Error: Chromium browser is open"
  echo "Please close the browser and restart the installation procedure"
  exit 2
fi

# Amazon have changed the SDK directory structure. Prior versions will need to delete the directory before updating.
SDK_DIR=$HOME/sdk-folder
if [ -d $SDK_DIR ]; then
  echo "Delete $SDK_DIR directory"
  rm -rf $SDK_DIR
fi

mkdir $SDK_DIR

if [ -d $RPI_SETUP_DIR ]; then
  rm -rf $RPI_SETUP_DIR
fi
git clone -b $RPI_SETUP_TAG git://github.com/xmos/vocalfusion-rpi-setup.git

# Execute (rather than source) the setup scripts
echo "Installing VocalFusion ${XMOS_DEVICE:3} Raspberry Pi Setup..."
if $RPI_SETUP_DIR/setup.sh $XMOS_DEVICE; then

  echo "Installing Amazon AVS SDK..."
  wget -O $AVS_SCRIPT https://raw.githubusercontent.com/xmos/avs-device-sdk/$AVS_DEVICE_SDK_TAG/tools/Install/$AVS_SCRIPT
  wget -O pi.sh https://raw.githubusercontent.com/xmos/avs-device-sdk/$AVS_DEVICE_SDK_TAG/tools/Install/pi.sh
  wget -O genConfig.sh https://raw.githubusercontent.com/xmos/avs-device-sdk/$AVS_DEVICE_SDK_TAG/tools/Install/genConfig.sh
  chmod +x $AVS_SCRIPT

  if ./$AVS_SCRIPT $CONFIG_JSON_FILE $AVS_DEVICE_SDK_TAG -s $DEVICE_SERIAL_NUMBER -x $XMOS_DEVICE; then
    echo "Type 'sudo reboot' below to reboot the Raspberry Pi and complete the AVS setup."
  fi
fi

popd > /dev/null
