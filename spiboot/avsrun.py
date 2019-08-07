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
def cleanup():
    global spi_boot_in_progress
    spi_boot_in_progress = False
    try:
        subprocess.call(['killall', 'SampleApp'])
    except:
        pass
    sys.exit()


def led_function():
    try:
        global spi_boot_in_progress
        while spi_boot_in_progress:
            subprocess.call(["./pi_hat_ctrl", "SET_LED_RGB", "22", "1", "1"])
        subprocess.call(["./pi_hat_ctrl", "SET_LED_RGB", "19", "23", "3"])
    except KeyboardInterrupt:#possibly not needed
        pass
    return

def do_spiboot():
    try:
        with open(os.devnull, 'w') as devnull:
            silence_process = subprocess.Popen(['aplay', '-c', '2', '-f', 'S16_LE', '-r', '48000', '/dev/zero'], stderr=devnull)
            spiboot_process = subprocess.Popen(["python", "/home/pi/vocalfusion_3510_avs_setup/spiboot/send_image_from_rpi.py", "/home/pi/vocalfusion_3510_avs_setup/spiboot/app_xk_xvf3510_l71_i2s_slave_spi_slave.bin"], stderr=devnull, stdout=devnull)

        spiboot_process.wait() #wait for spiboot to finish
        silence_process.terminate() #stop aplay
    except KeyboardInterrupt:
        spiboot_process.kill()
        time.sleep(2)
        silence_process.kill()
        #instead of returning error raise KeyboardInterrupt
        return -1
    return 0

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
        ret = do_spiboot()
        if ret != 0:
            cleanup()

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
                
                ret = do_spiboot()
                if ret != 0:
                    cleanup()

            if spi_boot_in_progress == False:
                time.sleep(3)
            pass
    except KeyboardInterrupt:
        try:
            spi_boot_in_progress = False #this will make led process exit
            time.sleep(1)
            subprocess.call(['killall', 'SampleApp']) #kill avs process
        except:
            pass
        


if __name__ == "__main__":
    #just call run_avs function
    p = Process(target=run_avs)
    p.start()
