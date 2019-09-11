#!/usr/bin/env bash
pushd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null
SETUP_DIR="$( pwd )"

INSTALL_BASE=${INSTALL_BASE:-"$HOME/sdk-folder"}
BUILD_FOLDER=${BUILD_FOLDER:-'sdk-build'}
THIRD_PARTY_FOLDER=${THIRD_PARTY_LOC:-'third-party'}
BUILD_PATH="$INSTALL_BASE/$BUILD_FOLDER"
THIRD_PARTY_PATH="$INSTALL_BASE/$THIRD_PARTY_FOLDER"
OUTPUT_CONFIG_FILE="$BUILD_PATH/Integration/AlexaClientSDKConfig.json"

RPI_SETUP_DIR=$SETUP_DIR/vocalfusion-rpi-setup

RPI_SETUP_TAG="v2.1.0"
#AVS_DEVICE_SDK_TAG="xmos_v1.13"
AVS_DEVICE_SDK_TAG="feature/avsrun_spiboot"
AVS_SCRIPT="setup.sh"

# Default value for XMOS device
XMOS_DEVICE="xvf3510"

# Default device serial number if nothing is specified
DEVICE_SERIAL_NUMBER="123456"

ALIASES="$HOME/.bash_aliases"
CURRENT_DIR="$( pwd )"
TEST_SCRIPT="$INSTALL_BASE/test.sh"

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
  wget -O $AVS_SCRIPT https://raw.githubusercontent.com/shuchitak/avs-device-sdk/$AVS_DEVICE_SDK_TAG/tools/Install/$AVS_SCRIPT
  wget -O pi.sh https://raw.githubusercontent.com/shuchitak/avs-device-sdk/$AVS_DEVICE_SDK_TAG/tools/Install/pi.sh
  wget -O genConfig.sh https://raw.githubusercontent.com/shuchitak/avs-device-sdk/$AVS_DEVICE_SDK_TAG/tools/Install/genConfig.sh
  chmod +x $AVS_SCRIPT

  echo
  echo "==============> CREATING AUTOSTART SCRIPT ============"
  echo


  # Set up autostart script
  AUTOSTART_SESSION="avsrun"
  AUTOSTART_DIR=$HOME/.config/lxsession/LXDE-pi
  AUTOSTART=$AUTOSTART_DIR/autostart
  if [ ! -f $AUTOSTART ]; then
      mkdir -p $AUTOSTART_DIR
      cp /etc/xdg/lxsession/LXDE-pi/autostart $AUTOSTART
  fi
  STARTUP_SCRIPT=$CURRENT_DIR/.avsrun-startup.sh

  while true; do
      read -p "Automatically run AVS SDK at startup (y/n)? " ANSWER
      case ${ANSWER} in
          n|N|no|NO )
              if grep $AUTOSTART_SESSION $AUTOSTART; then
                  # Remove startup script from autostart file
                  sed -i '/'"$AUTOSTART_SESSION"'/d' $AUTOSTART
              fi
              break;;
          y|Y|yes|YES )
              if ! grep $AUTOSTART_SESSION $AUTOSTART; then #avsrun not present
                  if ! grep "vocalfusion_3510_sales_demo" $AUTOSTART; then #vocalfusion_3510_sales_demo not present
                      # Append startup script if not already in autostart file
                      echo "@lxterminal -t $AUTOSTART_SESSION --geometry=150x50 -e $STARTUP_SCRIPT" >> $AUTOSTART
                  fi
              else #avsrun present
                  if grep "vocalfusion_3510_sales_demo" $AUTOSTART ; then #vocalfusion_3510_sales_demo present
                      # Remove startup script from autostart file
                      echo "Warning: Not adding avsrun in autostart since offline demo is already present. Start AVS by following instructions on vocalfusion_3510_sales_demo startup"
                      sed -i '/'"$AUTOSTART_SESSION"'/d' $AUTOSTART
                  fi
              fi
              break;;
      esac
  done
  if ./$AVS_SCRIPT $CONFIG_JSON_FILE -t $AVS_DEVICE_SDK_TAG -s $DEVICE_SERIAL_NUMBER -d $XMOS_DEVICE; then
    if [ ! -f $ALIASES ] ; then
      echo "Create .bash_aliases file"
      touch $ALIASES
    fi
    echo "Delete any existing avs aliases and rewrite them"
    sed -i '/avsrun/d' $ALIASES > /dev/null
    sed -i '/avsrun_no_spiboot/d' $ALIASES > /dev/null
    sed -i '/avsunit/d' $ALIASES > /dev/null
    sed -i '/avssetup/d' $ALIASES > /dev/null
    sed -i '/avsauth/d' $ALIASES > /dev/null
    sed -i '/AVS/d' $ALIASES > /dev/null
    sed -i '/AlexaClientSDKConfig.json/d' $ALIASES > /dev/null
    sed -i '/Remove/d' $ALIASES > /dev/null

    echo "alias avsrun=\"python3 $CURRENT_DIR/spiboot/avsrun.py\"" >> $ALIASES
    echo "alias avsrun_no_spiboot=\"$BUILD_PATH/SampleApp/src/SampleApp $OUTPUT_CONFIG_FILE $THIRD_PARTY_PATH/alexa-rpi/models\"" >> $ALIASES
    echo "alias avsunit=\"bash $TEST_SCRIPT\"" >> $ALIASES
    echo "avssetup() { f=\$(eval readlink -f \"\$1\"); bash $CURRENT_DIR/setup.sh \$f; }" >> $ALIASES
    echo "echo "Available AVS aliases:"" >> $ALIASES
    echo "echo -e "avsrun, avsunit, avssetup"" >> $ALIASES
    echo "echo "If authentication fails, please check $BUILD_PATH/Integration/AlexaClientSDKConfig.json"" >> $ALIASES
    echo "echo "To re-configure the AVS device SDK, please run avssetup with the appropriate JSON config file"" >> $ALIASES
    
    echo " "
    echo "Type 'sudo reboot' below to reboot the Raspberry Pi and complete the AVS setup."
  fi
fi

popd > /dev/null
