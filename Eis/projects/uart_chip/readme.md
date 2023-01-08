This is a UART synthesis of both a transmitter and receiver.
See simulation readme.md for further details

It's a simple test that simply reflects any ascii byte sent back to the Transmitter.

Note: Remember to cross the Tx and Rx signals.

# Summary
- protocol: 8N1
- baud: 115200

# Minicom client (aka trasnmitter)
Turn off "flow control" [Ctrl-a x o]

```$ minicom -b 115200 -o -D /dev/ttyUSB0```
