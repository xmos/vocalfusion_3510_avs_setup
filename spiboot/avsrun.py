#!/usr/bin/python
import subprocess
import os
import multiprocessing
from multiprocessing import Process
import threading
import signal
import time
import shutil

package_dir = os.path.dirname(os.path.abspath(__file__))
spi_boot_in_progress = True

def led_function():
    global spi_boot_in_progress
    while spi_boot_in_progress:
        subprocess.call(["./pi_hat_ctrl", "SET_LED_RGB", "22", "1", "1"])
    subprocess.call(["./pi_hat_ctrl", "SET_LED_RGB", "19", "23", "3"])
    return

def do_spiboot():
    try:
        with open(os.devnull, 'w') as devnull:
            silence_process = subprocess.Popen(['aplay', '-c', '2', '-f', 'S16_LE', '-r', '48000', '/dev/zero'], stderr=devnull)
            spiboot_process = subprocess.Popen(["python", os.path.join(package_dir, "send_image_from_rpi.py"), os.path.join(package_dir, "app_xk_xvf3510_l71_i2s_slave_spi_slave.bin")], stderr=devnull, stdout=devnull)

        spiboot_process.wait() #wait for spiboot to finish
        silence_process.terminate() #stop aplay
    except KeyboardInterrupt:
        try:
            spiboot_process.kill()
            silence_process.kill()
        except:
            pass
        print('do spiboot caught a ctrl+c')
        raise KeyboardInterrupt('do_spiboot caught a ctrl+c')
        #instead of returning error raise KeyboardInterrupt
    return

def run_avs():
    try:
        global spi_boot_in_progress
        avs = None
        #spiboot before doing anything else
        spi_boot_in_progress = True
        led = threading.Thread(target=led_function)
        shutil.copy2("/home/pi/sdk-folder/third-party/pi_hat_ctrl/pi_hat_ctrl", ".")
        led.start()
        do_spiboot()

        while True:
            try:
                i2c_detect = subprocess.check_output(['i2cdetect', '-y', '1', '0x2c', '0x2c'])
            except:
                continue

            if b'2c' in i2c_detect:
                #if this is the first time we've seen the device after spiboot
                if spi_boot_in_progress == True:
                    #Do a spiboot just in case there's i2s slave FW in flash and on powering the device back up, the FW in flash is running
                    while True: #keep spi-booting till device appears on i2c since we want to be 100% sure the device is there before starting avs
                        do_spiboot()
                        time.sleep(2)
                        #make sure that the device is seen on i2c
                        i2c_detect = subprocess.check_output(['i2cdetect', '-y', '1', '0x2c', '0x2c'])
                        if b'2c' in i2c_detect:
                            break

                    spi_boot_in_progress = False
                    led.join() #wait for led thread to exit
                    #start avs
                    avs = subprocess.Popen(["/home/pi/sdk-folder/sdk-build/SampleApp/src/SampleApp", "/home/pi/sdk-folder/sdk-build/Integration/AlexaClientSDKConfig.json", "/home/pi/sdk-folder/third-party/alexa-rpi/models"])
            else:
                #if this is the first time we've seen the device not present, stop avs and start led thread
                if spi_boot_in_progress == False:
                    spi_boot_in_progress = True
                    led = threading.Thread(target=led_function)
                    avs.kill() 
                    avs = None
                    led.start()
                
                do_spiboot()

            if spi_boot_in_progress == False:
                time.sleep(3)
            pass
    except KeyboardInterrupt:
        print('run_avs caught a ctrl+c')
        spi_boot_in_progress = False #this will make led process exit
        if avs != None:
            avs.kill()
        time.sleep(1)
        


if __name__ == "__main__":
    run_avs()
