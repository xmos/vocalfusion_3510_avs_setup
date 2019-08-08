#!/usr/bin/python
import subprocess
import os
import multiprocessing
from multiprocessing import Process
import threading
import smbus
import signal
import sys
import time
import shutil

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
            silence_process = subprocess.Popen(['aplay', '-c', '2', '-f', 'S16_LE', '-r', '48000', '/dev/zero'])
            spiboot_process = subprocess.Popen(["python", "send_image_from_rpi.py", "app_xk_xvf3510_l71_i2s_slave_spi_slave.bin"])

        spiboot_process.wait() #wait for spiboot to finish
        silence_process.terminate() #stop aplay
    except KeyboardInterrupt:
        spiboot_process.kill()
        silence_process.kill()
        print('do spiboot caught a ctrl+c')
        raise KeyboardInterrupt('do_spiboot caught a ctrl+c')
        #instead of returning error raise KeyboardInterrupt
    return

def run_avs():
    try:
        global spi_boot_in_progress
        #spiboot before doing anything else
        spi_boot_in_progress = True
        led = threading.Thread(target=led_function)
        while True:
            try:
                shutil.copy2("/home/pi/sdk-folder/third-party/pi_hat_ctrl/pi_hat_ctrl", ".")
                break
            except:
                pass

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
                    #wait 2 seconds here
                    spi_boot_in_progress = False
                    time.sleep(2)
                    led.join() #wait for led thread to exit
                    #start avs
                    avs = subprocess.Popen(["/home/pi/sdk-folder/sdk-build/SampleApp/src/SampleApp", "/home/pi/sdk-folder/sdk-build/Integration/AlexaClientSDKConfig.json", "/home/pi/sdk-folder/third-party/alexa-rpi/models"])
            else:
                #if this is the first time we've seen the device not present, stop avs and start led thread
                if spi_boot_in_progress == False:
                    spi_boot_in_progress = True
                    led = threading.Thread(target=led_function)
                    avs.kill() #set avs to None
                    led.start()
                
                do_spiboot()

            if spi_boot_in_progress == False:
                time.sleep(3)
            pass
    except KeyboardInterrupt:
        try:
            print('run_avs caught a ctrl+c')
            spi_boot_in_progress = False #this will make led process exit
            time.sleep(1)
            subprocess.call(['killall', 'SampleApp']) #kill avs process
        except:
            pass
        


if __name__ == "__main__":
    run_avs()
