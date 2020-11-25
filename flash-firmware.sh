#!/bin/bash

avr-objcopy -O ihex -R .eeprom nelua_cache/examples/arduino nelua_cache/examples/arduino.hex
sudo avrdude -F -V -c arduino -p atmega328p -P /dev/ttyACM0 -b 115200 -U flash:w:nelua_cache/examples/arduino.hex