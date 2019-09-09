# Copyright (c) 2019, XMOS Ltd, All rights reserved
# requires dtparam=spi=on in /boot/config.txt

"""
This script configures the XVF3510 board in boot from SPI slave and load a binary file.
It requires a bin file as input parameter
"""

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import os
import time
import argparse
import spidev
import RPi.GPIO as GPIO
import smbus

# TODO: the function below is not supported yet
# def wait_until_ready_signal(p_ready):
#    active = 0
#    while active == 0:
#        active = GPIO.input(p_ready)
#        time.sleep(.001)

def bit_reversed_byte(byte_to_reverse):
    """
    Function to reverse the bit-order of a byte

    Args:
        byte_to_reverse: byte to process

    Retruns:
        byte in reversed order
    """
    return int('{:08b}'.format(byte_to_reverse)[::-1], 2)

def set_boot_sel():
    """
    Function to set XVF3510 board in SPI slave boot mode

    Args:
        None

    Returns:
        None
    """

    bus = smbus.SMBus(1)

    # reset BOOT_SEL
    bus.write_byte_data(0x20, 3, 0xFE)
    bus.write_byte_data(0x20, 7, 0xFF)

    state = {}
    for i in [2, 6]:
        state[i] = bus.read_byte_data(0x20, i)

    # start reset
    data_to_write = 0x00 | (state[2] & 0xDF)
    bus.write_byte_data(0x20, 2, data_to_write)
    data_to_write = 0x00 | (state[6] & 0xDF)
    bus.write_byte_data(0x20, 6, data_to_write)
    # set BOOT_SEL high
    data_to_write = 0x01
    bus.write_byte_data(0x20, 3, data_to_write)
    data_to_write = 0xFE
    bus.write_byte_data(0x20, 7, data_to_write)
    # stop reset
    data_to_write = 0x20 | (state[2] & 0xDF)
    bus.write_byte_data(0x20, 2, data_to_write)
    data_to_write = 0x20 | (state[6] & 0xDF)
    bus.write_byte_data(0x20, 6, data_to_write)


parser = argparse.ArgumentParser(description='Load an image via SPI slave from an RPi')
parser.add_argument('bin_filename', help='binary file name')

args = parser.parse_args()

if os.path.exists(args.bin_filename) is False:
    print("Error: input file {} not found".format(args.bin_filename))
    exit(1)


#setup GPIO
GPIO.setmode(GPIO.BOARD)
p_ready = 22 #pin 22 on the header GPIO.setmode(GPIO.BOARD)
GPIO.setup(p_ready, GPIO.IN)

#setup SPI
spi = spidev.SpiDev()
bus_spi = 0
device = 0
spi.open(bus_spi, device)

#SPI Settings
spi.max_speed_hz = 5000000 #about 2.6MHz in reality on RPI3
spi.mode = 0b00 #XMOS supports 00 or 11

spi_block_size = 4096 #Limitation in spidev and xfer2 doesn't work!

set_boot_sel()

data = []
with open(args.bin_filename, "rb") as f:
    bytes_read = f.read()
    #turn byte array into int list
    data = [ord(byte) for byte in bytes_read]
    binary_size = len(data)
    block_count = 0
    print('Read file "{0}" size: {1} Bytes'.format(args.bin_filename, binary_size))
    if binary_size % spi_block_size != 0:
        print("Warning - binary file not a multiple of {} - {} remainder".format( \
            spi_block_size, binary_size % spi_block_size))
    while binary_size > 0:
        #block = data[:spi_block_size]
        block = [bit_reversed_byte(byte) for byte in data[:spi_block_size]]
        del data[:spi_block_size]
        binary_size = len(data)
        print("Sending {} Bytes in block {} checksum 0x{:X}".format( \
            len(block), block_count, sum(block)))
        spi.xfer(block)

        if block_count == 0:
            #Long delay for PLL reboot
            time.sleep(0.1)
        elif binary_size > 0:
            #Do not wait on last block
            time.sleep(0.1)
        block_count += 1
print("Sending complete")

bus = smbus.SMBus(1)

# reset BOOT_SEL
data_to_write = 0xFE
bus.write_byte_data(0x20, 3, data_to_write)
data_to_write = 0xFF
bus.write_byte_data(0x20, 7, data_to_write)


GPIO.cleanup()
