#!/usr/bin/env bash
pushd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null
SETUP_DIR="$( pwd )"
RPI_SETUP_DIR=$SETUP_DIR/vocalfusion-rpi-setup

RPI_SETUP_TAG="v2.0.0"
AVS_DEVICE_SDK_TAG="v1.13"
AVS_SCRIPT="setup.sh"

# Default value for XMOS device
XMOS_DEVICE="xvf3510"

# Default device serial number if nothing is specified
DEVICE_SERIAL_NUMBER="123456"

show_help() {
  echo  'Usage: auto_install.sh [OPTIONS]'
  echo  'A config.json file must be present in the current working directory.'
  echo  'The config.json can be downloaded from developer portal and must contain the following:'
  echo  '   "clientId": "<Auth client ID>"'
  echo  '   "productId": "<your product name for device>"'
  echo  ''
  echo  'Optional parameters'
  echo  '  -s <serial-number>  If nothing is provided, the default device serial number is 123456'
  echo  '  -d <device-type>    XMOS device to setup: default xvf3510, possible value xvf3500'
  echo  '  -h                  Display this help and exit'
}

if [[ $# -lt 1 ]]; then
    show_help
    exit 1
fi

CONFIG_JSON_FILE="config.json"
if [ ! -f "$CONFIG_JSON_FILE" ]; then
    echo "Config json file not found!"
    show_help
    exit 1
fi
shift 1

OPTIONS=s:x:h
while getopts "$OPTIONS" opt ; do
    case $opt in
        s )
            DEVICE_SERIAL_NUMBER="$OPTARG"
            ;;
        x )
            XMOS_DEVICE="$OPTARGS"
            ;;
        h )
            show_help
            exit 1
            ;;
    esac
done

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
echo "Installing VocalFusion 3510 Raspberry Pi Setup..."
if $RPI_SETUP_DIR/setup.sh xvf3510; then

  echo "Installing Amazon AVS SDK..."
  wget -O $AVS_SCRIPT https://raw.githubusercontent.com/xmos/avs-device-sdk/$AVS_DEVICE_SDK_TAG/tools/Install/$AVS_SCRIPT
  wget -O pi.sh https://raw.githubusercontent.com/xmos/avs-device-sdk/$AVS_DEVICE_SDK_TAG/tools/Install/pi.sh
  wget -O genConfig.sh https://raw.githubusercontent.com/xmos/avs-device-sdk/$AVS_DEVICE_SDK_TAG/tools/Install/genConfig.sh
  chmod +x $AVS_SCRIPT

  if ./$AVS_SCRIPT $CONFIG_JSON_FILE $AVS_DEVICE_SDK_TAG -s $DEVICE_SERIAL_NUMBER -d $XMOS_DEVICE; then
    echo "Type 'sudo reboot' below to reboot the Raspberry Pi and complete the AVS setup."
  fi
fi

# Overwrite avsrun alias to ensure I2S clk is always reinitialised
sed -i '/avsrun=/d' /home/pi/.bash_aliases > /dev/null
echo "alias avsrun=\"sudo $RPI_SETUP_DIR/resources/clk_dac_setup/setup_bclk > /dev/null; /home/pi/sdk-folder/sdk-build/SampleApp/src/SampleApp /home/pi/sdk-folder/sdk-build/Integration/AlexaClientSDKConfig.json /home/pi/sdk-folder/third-party/alexa-rpi/models\"" >> /home/pi/.bash_aliases

popd > /dev/null
