# Make the Pi boot from USB

Start by flashing Raspberry Pi OS (Lite) onto a SD card en boot the Pi.
Then run the following commands in the terminal:

```shell
# Update the EEPROM firmware
sudo apt update && sudo apt full-upgrade
sudo rpi-eeprom-update -d -a
sudo reboot

# Update firmware of the Pi
sudo rpi-update
sudo reboot

# Enable USB boot mode
echo program_usb_boot_mode=1 | sudo tee -a /boot/config.txt
sudo reboot
```

Now you can remove the SD card and plug an SSD with Raspberry Pi OS Lite in the Rasbperry Pi and boot it.

*At first, I got a bunch of errors, and the system did not boot, then I moved the SSD from the USB3.0 port to the USB2.0 port. Then all of a sudden it worked...*
