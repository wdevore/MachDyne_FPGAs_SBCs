# Various projects for the Eis SBC

# ldprog
- First pull from github: https://github.com/machdyne/ldprog
- ```cp ldprog /usr/local/bin/```

A few things to try if failing to upload:

1. Run the ldprog command with sudo (only needed if you **haven't** added a udev rule):

```$ sudo ldprog -i -s /media/RAMDisk/hardware.bin```

2. Run:

```$ dmesg -w```

and then plug in the device, you should see something like:
```
[578178.945868] usb 1-3.1.4: new full-speed USB device number 20 using xhci_hcd
[578179.055144] usb 1-3.1.4: New USB device found, idVendor=2e8a, idProduct=1025, bcdDevice= 0.00
[578179.055160] usb 1-3.1.4: New USB device strings: Mfr=1, Product=2, SerialNumber=0
[578179.055168] usb 1-3.1.4: Product: Müsli USB Pmod
[578179.055174] usb 1-3.1.4: Manufacturer: Raspberry Pi
```

```grep 1025 /sys/bus/usb/devices//*/idProduct```
```
/sys/bus/usb/devices//1-1.4.1/idProduct:1025

/sys/bus/usb/devices/1-1/1-1.4/1-1.4.1/
```

3. Add a udev rule for vendor ID 2e8a and product ID 1025. in */etc/udev/rules.d/80-fpga-serial.rules*

# Working rule:
```
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2e8a", ATTRS{idProduct}=="1025", MODE="0666", GROUP="plugdev" ENV{ID_MM_DEVICE_IGNORE}="1"
```

# NON working rules:
```
SUBSYSTEM=="usb", GROUP="plugdev", ATTR{idVendor}=="2e8a", ATTRS{idProduct}=="1025"
```

```
SUBSYSTEM=="usb", DRIVERS=="usb", ATTR{idVendor}=="2e8a", ATTRS{idProduct}=="1025"
```

```
SUBSYSTEMS=="usb", SUBSYSTEM=="usb", DRIVERS=="usb", GROUP="plugdev", ATTR{idVendor}=="2e8a", ATTRS{idProduct}=="1025"
```

```
SUBSYSTEMS=="usb", ATTR{idVendor}=="2e8a", ATTRS{idProduct}=="1025", MODE="0660", TAG+="uaccess"
```

```sudo udevadm monitor```

```
KERNEL[4537.624155] add      /devices/pci0000:00/0000:00:14.0/usb1/1-1/1-1.4/1-1.4.1 (usb)
KERNEL[4537.629952] add      /devices/pci0000:00/0000:00:14.0/usb1/1-1/1-1.4/1-1.4.1/1-1.4.1:1.0 (usb)
KERNEL[4537.630088] bind     /devices/pci0000:00/0000:00:14.0/usb1/1-1/1-1.4/1-1.4.1 (usb)
UDEV  [4537.635719] add      /devices/pci0000:00/0000:00:14.0/usb1/1-1/1-1.4/1-1.4.1 (usb)
UDEV  [4537.637487] add      /devices/pci0000:00/0000:00:14.0/usb1/1-1/1-1.4/1-1.4.1/1-1.4.1:1.0 (usb)
UDEV  [4537.640960] bind     /devices/pci0000:00/0000:00:14.0/usb1/1-1/1-1.4/1-1.4.1 (usb)
```

```sudo udevadm control --reload-rules```

See:
- https://linuxconfig.org/tutorial-on-how-to-write-basic-udev-rules-in-linux
- https://askubuntu.com/questions/1021547/writing-udev-rule-for-usb-device
- https://wiki.archlinux.org/title/udev

# openFPGALoader
- https://trabucayre.github.io/openFPGALoader/index.html

sudo apt install libftdi1-2 libftdi1-dev libhidapi-hidraw0 libhidapi-dev libudev-dev zlib1g-dev

cmake .. -DENABLE_CMSISDAP=OFF -DBUILD_STATIC=OFF -DENABLE_LIBGPIOD=OFF -DENABLE_UDEV=ON -DLINK_CMAKE_THREADS=ON
OR
cmake .. -DENABLE_CMSISDAP=OFF -DBUILD_STATIC=OFF -DENABLE_LIBGPIOD=OFF -DENABLE_UDEV=OFF -DLINK_CMAKE_THREADS=ON

make -j$(nproc)

