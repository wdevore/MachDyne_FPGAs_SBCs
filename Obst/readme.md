# Description
Build a basic monitor system that communicates via UART and VGA.

[Obst](https://machdyne.com/product/obst-computer/) is a Lattice ECP5 FPGA (LFE5U-12F). [Github](https://github.com/machdyne/obst).

# Tasks
- Blinky (**DONE**)
  - makefile (**DONE**)
  - lpf (**DONE**)
  - LED PMOD OR on board RGB (**DONE**)
  - system verilog file (**DONE**)
- VGA
- UART
- Audio
- TinyUSB (keyboard, etc.) OR PS2.
- RISC-V Monitor program

# Makefile

# openFPGALoader
- https://trabucayre.github.io/openFPGALoader/index.html

## Note!
Make sure the Tigard JTAG switch is **firmly** in place. If it is loose openFPGALoader can't find/detect the FPGA.

To help, you can run these command(s) to inspect the FPGA via the Tigard (Note: Tigard is a converter device):
```sh
openFPGALoader -c tigard --detect
```
Produces:
```
Jtag frequency : requested 6.00MHz   -> real 6.00MHz  
index 0:
	idcode 0x21111043
	manufacturer lattice
	family ECP5
	model  LFE5U-12
	irlength 8
```

# udev
Add a udev rules. I have several I use that are at the root level:
- 80-fpga-serial.rules
- 85-fpga-machdyne.rules
- 99-ftdi.rules
- 99-openfpgaloader.rules

# ftdi
Make sure you have the ftdi runtime installed.
```sh
sudo apt install libftdi1-2 libftdi1-dev libhidapi-hidraw0 libhidapi-dev libudev-dev zlib1g-dev

cmake .. -DENABLE_CMSISDAP=OFF -DBUILD_STATIC=OFF -DENABLE_LIBGPIOD=OFF -DENABLE_UDEV=ON -DLINK_CMAKE_THREADS=ON
OR
cmake .. -DENABLE_CMSISDAP=OFF -DBUILD_STATIC=OFF -DENABLE_LIBGPIOD=OFF -DENABLE_UDEV=OFF -DLINK_CMAKE_THREADS=ON

make -j$(nproc)
```

To make a FTDI breakout work on Ubuntu:

Open the file /etc/group with root permissions:

sudo nano /etc/group
After that, search for tty:x5: and dialout:x20:

Add your user to this groups typing your username in front of each line:

```
tty:x5:<user>
dialout:x20:<user>
```

You can also use the next two commands to avoid search for the file:

```sh
sudo usermod -aG tty <user>
sudo usermod -aG dialout <user>
sudo usermod -aG plugdev <user>
```
Where <user> = $USER, is your user name.

Finally, reboot your computer.

If you want to use udev rules, connect the FTDI Module, then run:

lsusb
This will show the vendorID and the productID. For example:

Bus 001 Device 106: ID 0403:6014 Future Technology Devices International, Ltd FT232H Single HS USB-UART/FIFO IC

Tigard
Bus 001 Device 024: ID 0403:6010 Future Technology Devices International, Ltd FT2232C/D/H Dual UART/FIFO IC


Then, create a rule like this:

ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="0660", GROUP="dialout"

Some require a USB subsystem added:
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1d50", ATTRS{idProduct}=="602b", MODE="0660", GROUP="plugdev", TAG+="uaccess"


# dmesg
```sh
sudo dmesg -w

[802375.000710] ftdi_sio 1-11.1.4.1:1.1: FTDI USB Serial Device converter detected
[802375.000796] usb 1-11.1.4.1: Detected FT2232H
[802375.001002] usb 1-11.1.4.1: FTDI USB Serial Device converter now attached to ttyUSB1
```

```sh
sudo dmesg | grep FTDI
```

Obst dmesg connect info:
```log
[803112.072000] usb 1-6: FTDI USB Serial Device converter now attached to ttyUSB1
[803488.382873] usb 1-11.1.4.4: new full-speed USB device number 49 using xhci_hcd
[803488.523821] usb 1-11.1.4.4: New USB device found, idVendor=16d0, idProduct=116d, bcdDevice= 0.00
[803488.523836] usb 1-11.1.4.4: New USB device strings: Mfr=1, Product=2, SerialNumber=3
[803488.523869] usb 1-11.1.4.4: Product: Obst DFU Bootloader
[803488.523875] usb 1-11.1.4.4: Manufacturer: Lone Dynamics Corporation
[803488.523878] usb 1-11.1.4.4: SerialNumber: 000000
[803493.066596] usb 1-11.1.4.4: USB disconnect, device number 49
```