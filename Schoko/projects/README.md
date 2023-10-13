# Various projects for the Schoko SBC

# openFPGALoader
- https://trabucayre.github.io/openFPGALoader/index.html

sudo apt install libftdi1-2 libftdi1-dev libhidapi-hidraw0 libhidapi-dev libudev-dev zlib1g-dev

cmake .. -DENABLE_CMSISDAP=OFF -DBUILD_STATIC=OFF -DENABLE_LIBGPIOD=OFF -DENABLE_UDEV=ON -DLINK_CMAKE_THREADS=ON
OR
cmake .. -DENABLE_CMSISDAP=OFF -DBUILD_STATIC=OFF -DENABLE_LIBGPIOD=OFF -DENABLE_UDEV=OFF -DLINK_CMAKE_THREADS=ON

make -j$(nproc)

# Ecp5
- https://github.com/YosysHQ/prjtrellis
- http://bygone.clairexen.net/icestorm/  related but not ECP5
- https://github.com/YosysHQ/nextpnr
- https://trabucayre.github.io/openFPGALoader/guide/install.html#install

```
cmake -DARCH=ecp5 -DTRELLIS_INSTALL_PREFIX=/usr/local .
```

```
$ openFPGALoader --scan-usb

found 17 USB device
Bus device vid:pid       probe type      manufacturer serial               product
001 037    0x0403:0x6010 FTDI2232        SecuringHardware.com TG1106c8             Tigard V1.1
```

# Tigard
- https://github.com/tigard-tools/tigard

# dfu-util

```
new full-speed USB device number 44 using xhci_hcd
usb 1-1.4.1: New USB device found, idVendor=16d0, idProduct=116d, bcdDevice= 0.00
usb 1-1.4.1: New USB device strings: Mfr=1, Product=2, SerialNumber=3
usb 1-1.4.1: Product: Schoko DFU Bootloader
usb 1-1.4.1: Manufacturer: Lone Dynamics Corporation
usb 1-1.4.1: SerialNumber: 000000
usb 1-1.4.1: USB disconnect, device number 44
```

# openOCD
## tigard-jtag.cfg:

- https://github.com/tigard-tools/tigard#jtag-debug-on-jtag-or-cortex-header
- https://github.com/emard/galaksija/blob/master/proj/lattice/scripts/ecp5-ocd.sh
- https://openocd.org/doc/html/index.html#toc-About-1

```
interface ftdi
ftdi_vid_pid 0x0403 0x6010
ftdi_channel 1
adapter_khz 2000
ftdi_layout_init 0x0038 0x003b
ftdi_layout_signal nTRST -data 0x0010
ftdi_layout_signal nSRST -data 0x0020
transport select jtag
```

## lfe5u-45f.cfg:
The 45F has ~60K words.

```
jtag newtap ecp5 tap -irlen 8 -expected-id 0x41112043 -irmask 0xFF -ircapture 0x1
```

And then create an SVF file instead of BIT file:

```
$ ecppack --svf output/blinky.svf output/schoko_blinky_out.config
```

And then program it:

```
$ sudo openocd -f tigard-jtag.cfg -f lfe5u-45f.cfg -c "transport select jtag; init; scan_chain; svf -tap ecp5.tap -quiet -progress blinky.svf; exit"
```

# Building FPGA toolchain Yosys

## Yosys
If new then do:
- git clone xxx
- make -j$(nproc)

Otherwise
- git pull

## Nextpnr
- git pull
- git submodule update

## Trellis
- cmake . -DARCH=ecp5 -DTRELLIS_INSTALL_PREFIX=/usr/local
- make -j$(nproc)
- sudo make install

## RISC-V toolchain
???

## ecpbram
ecpbram and icebram are used to put the firmware into the bitstream.

The bitstream includes random data (firmware_seed.hex), those tools find the random data and replace it with the actual firmware (firmware.hex).

This lets you update the firmware quickly without having to rebuild the bitstream, which can take several minutes.