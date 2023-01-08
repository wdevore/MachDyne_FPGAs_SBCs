
This is a UART synthesis of both a transmitter and receiver.
See simulation readme.md for further details

# Summary
- protocol: 8N1
- baud: 115200

# Minicom
Turn off "flow control" [Ctrl-a x o]

```$ minicom -b 115200 -o -D /dev/ttyUSB0```


# Links
- https://ethertubes.com/raspberry-pi-rts-cts-flow-control/
- https://github.com/raspberrypi/pico-examples/blob/master/uart/uart_advanced/uart_advanced.c
- https://forums.raspberrypi.com/viewtopic.php?t=339576
