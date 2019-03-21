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

2. Ensure running kernel version matches headers kernel headers package. A typical system requires the following `--reinstall` command:

   ```sudo apt-get install --reinstall raspberrypi-bootloader raspberrypi-kernel```

   followed by a reboot.

3. Clone the vocalfusion_3510_avs_setup repository:

   ```git clone https://github.com/xmos/vocalfusion_3510_avs_setup```

4. Register Alexa with AVS by following https://github.com/alexa/avs-device-sdk/wiki/Create-Security-Profile.

   Ensure that the device origins and return fields are completed. From `My products` select `manage` and then `security profile`. Now add http://localhost:3000 to the `Allowed origins` and http://localhost:3000/authresponse to the `Allowed return URLs`. 
   
   Note: The *Allowed Origins* and *Allowed Return URLs* should be entered as **http**, not **https**.

   Note: It can be easier to configure your new Alexa device and Amazon developer account from a browser on your Raspberry Pi, as you can then easily copy the *ProductID*, *ClientID* and *ClientSecret* keys.

5. Run the installation script by entering:

   ``` cd vocalfusion_3510_avs_setup```

   ```./auto_install.sh```

   Read and accept the AVS Device SDK license agreement.

6. You will be prompted enter your Alexa device details and asked whether you want the Sample App to run automatically when the Raspberry Pi boots. It is recommended that you respond "yes" to this option. Your Alexa device details are the *ProductID*, the *ClientID* and *ClientSecret* keys as generated in the previous step. You will also be prompted to enter a serial number and define your location.

7. Read and accept the Sensory license agreement. Wait for the script to complete the installation. The script is configuring the Raspberry Pi audio system, downloading and updating dependencies, building and configuring the AVS Device SDK. It takes around 30 minutes to complete.

8. As a final step, the script will open http://localhost:3000 in a browser on the Raspberry Pi. Enter your Amazon Developer credentials and close the browser window when prompted. (You won't have to do this if you already have a valid configuration file.) If you see a `400 Bad Request - HTTP` error. Go back to 4 above and check the `Allowed origins` and the `Allowed return URLs` have been correctly set and saved. Now refresh the browser window with the 404 error.

9. Enter `sudo reboot` to reboot the Raspberry Pi and complete the installation.

 **IMPORTANT:** An unresolved setup issue means that the **Raspberry Pi should be rebooted twice** after installation before the system will respond.

10. If you selected the option to run the Sample App on boot you should now be able to execute an AVS command such as "Alexa, what time is it?". The LED on the Pi HAT board will change colour when the system hears the "Alexa" keyword, and will then cycle back and forth whilst waiting for a response from the Amazon AVS server.

## Running the AVS SDK Sample App
The automated installation script creates a number of aliases which can be used to execute the AVS Device SDK client, or run the unit tests:
- `avsrun` to run the Sample App.
- `avsauth` to re-authenticate your Alexa device details (invoke Amazon's `avs_auth.sh`).
- `avsunit` to run the unit tests (invoke Amazon's `avs_test.sh`).
- `avssetup` to re-install the Sample App (re-run XMOS modified `setup.sh`).

## Using different Amazon details
To change client and product ID, run `avssetup`. It will ask you to type in your IDs and invoke `avsauth` for you. As a result the SDK JSON file will be updated so subsequent `avsrun` can use the new details.
