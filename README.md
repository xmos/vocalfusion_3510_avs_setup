# xCORE VocalFusion XVF3510 kit for Amazon AVS on a Raspberry Pi

The XMOS **xCORE VocalFusion XVF3510 kit for Amazon AVS** provides far-field voice capture using the XMOS XVF3500 voice processor.

Combined with a Raspberry Pi running the Amazon Alexa Voice Service (AVS) Software Development Kit (SDK), this kit allows you to quickly prototype and evaluate talking with Alexa.

To find out more, visit: https://xmos.com/vocalfusion-avs  
and: https://developer.amazon.com/alexa-voice-service

This repository provides a simple-to-use automated script to install the Amazon AVS SDK on a Raspberry Pi and configure the Raspberry Pi to use the **xCORE VocalFusion XVF3510 kit for Amazon AVS** for audio.

## Prerequisites
You will need:

- **xCORE VocalFusion XVF3510 kit for Amazon AVS**: XK-VF3510-L71
- Raspberry Pi 3
- Micro-USB power supply (min. 2A)
- MicroSD card (min. 16GB)
- Powered mono speaker with audio 3.5mm analogue plug
- Monitor with HDMI input
- HDMI cable
- Fast-Ethernet connection with internet connectivity

You will also need an Amazon Developer account: https://developer.amazon.com

## Hardware setup
Setup your hardware by following the **Hardware Setup**.

## AVS SDK installation and Raspberry Pi audio setup
The **Getting Started Guide** details setup steps up until this point. What follows are setup steps specific to the AVS SDK.

1. Install Raspbian (Stretch) on the Raspberry Pi.

   Recommended version of NOOBS is available here: http://downloads.raspberrypi.org/NOOBS/images/NOOBS-2018-10-11/NOOBS_v2_9_0.zip
   
   IMPORTANT: To prevent inadvertent possibly incompatible updates, ensure that there are no network cables connected to the Pi. 
   
   On first boot, follow the instructions to set your locale settings and connect to a WiFi network but **SKIP THE UPDATE STEP**.

2. Clone the vocalfusion_3510_avs_setup repository:

   ```git clone https://github.com/xmos/vocalfusion_3510_avs_setup```

3. Close any other application such as browsers to avoid the Raspberry Pi to freeze during the AVS SDK installation.

4. Register Alexa with AVS and save a *config.json* file by following https://github.com/alexa/avs-device-sdk/wiki/Create-Security-Profile.

5. Copy the *config.json* into the directory `vocalfusion_3510_avs_setup`

6. Run the installation script by entering:

   ``` cd vocalfusion_3510_avs_setup```

   ```./auto_install.sh config.json```

   Read and accept the AVS Device SDK license agreement.

7. You will be asked whether you want the Sample App to run automatically when the Raspberry Pi boots. It is recommended that you respond "yes" to this option.

8. Read and accept the Sensory license agreement. Wait for the script to complete the installation. The script is configuring the Raspberry Pi audio system, downloading and updating dependencies, building and configuring the AVS Device SDK. It takes around 30 minutes to complete.

9. Enter `sudo reboot` to reboot the Raspberry Pi and complete the installation.

10. If you selected the option to run the Sample App on boot you should now be able to complete the registration by following the steps from 2 onward here:
https://github.com/alexa/avs-device-sdk/wiki/Raspberry-Pi-Quick-Start-Guide-with-Script#finish-authorization-using-login-with-amazon

11. Now you can execute an AVS command such as "Alexa, what time is it?". The LED on the Pi HAT board will change colour when the system hears the "Alexa" keyword, and will then cycle back and forth whilst waiting for a response from the Amazon AVS server.

## Running the AVS SDK Sample App
The automated installation script creates a number of aliases which can be used to execute the AVS Device SDK client, or run the unit tests:
- `avsrun` to run the Sample App.
- `avsunit` to run the unit tests (invoke Amazon's `test.sh`).
- `avssetup` to re-install the Sample App (re-run XMOS modified `setup.sh`).

## Using different Amazon details
To change client and product ID, run `avssetup`. It will ask you to type in your IDs and invoke `avsauth` for you. As a result the SDK JSON file will be updated so subsequent `avsrun` can use the new details.
