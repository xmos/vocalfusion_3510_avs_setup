#!/usr/bin/env bash
pushd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null
SETUP_DIR="$( pwd )"
RPI_SETUP_DIR=$SETUP_DIR/vocalfusion-rpi-setup

RPI_SETUP_TAG="v1.3.1"
AVS_DEVICE_SDK_TAG="xmos_v1.6"
AVS_SCRIPT="setup.sh"

# Amazon have changed the SDK directory structure. Prior versions will need to delete the directory before updating.
SDK_DIR=$HOME/sdk-folder
if [ -d $SDK_DIR ]; then
  if [ -d $SDK_DIR/avs-device-sdk ] && [ $(git -C $SDK_DIR/avs-device-sdk rev-parse --abbrev-ref HEAD) = $AVS_DEVICE_SDK_TAG ]; then
    # SDK build folder is aligned with latest Amazon changes
    :
  else
    echo "Error: $SDK_DIR is out of date. Please delete directory and then rerun."
    echo "Exiting install script."
    popd > /dev/null
    return
  fi
fi

if [ ! -d $RPI_SETUP_DIR ]; then
  git clone -b $RPI_SETUP_TAG git://github.com/xmos/vocalfusion-rpi-setup.git
else
  if ! git -C $RPI_SETUP_DIR diff-index --quiet HEAD -- ; then
    echo "Changes found in $RPI_SETUP_DIR. Please revert changes, or delete directory, and then rerun."
    echo "Exiting install script."
    popd > /dev/null
    return
  fi

  echo "Updating VocalFusion Raspberry Pi Setup"
  git -C $RPI_SETUP_DIR fetch > /dev/null
  git -C $RPI_SETUP_DIR checkout $RPI_SETUP_TAG > /dev/null

fi

# Install necessary packages for dev kit
sudo apt-get -y install libusb-1.0-0-dev libreadline-dev libncurses-dev audacity

# Execute (rather than source) the setup scripts
echo "Installing VocalFusion 3510 Raspberry Pi Setup..."
if $RPI_SETUP_DIR/setup.sh xvf3510; then

  echo "Installing Amazon AVS SDK..."
  wget -O $AVS_SCRIPT https://raw.githubusercontent.com/xmos/avs-device-sdk/$AVS_DEVICE_SDK_TAG/tools/Install/$AVS_SCRIPT
  chmod +x $AVS_SCRIPT

  if ./$AVS_SCRIPT xvf3510; then
    echo "Type 'sudo reboot' below to reboot the Raspberry Pi and complete the AVS setup."
  fi
fi

# Overwrite avsrun alias to ensure I2S clk is always reinitialised
sed -i '/avsrun=/d' /home/pi/.bash_aliases > /dev/null
echo "alias avsrun=\"sudo $RPI_SETUP_DIR/resources/clk_dac_setup/setup_bclk > /dev/null; /home/pi/sdk-folder/sdk-build/SampleApp/src/SampleApp /home/pi/sdk-folder/sdk-build/Integration/AlexaClientSDKConfig.json /home/pi/sdk-folder/third-party/alexa-rpi/models\"" >> /home/pi/.bash_aliases

popd > /dev/null
