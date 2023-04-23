# Description
A very basic Tx component

# Minicom
Tigard's UART port is on the first listed USB port. Note: if you have already plugged in some other UART device prior then the Tigard's port will be higher, for example, **ttyUSB1**.
```minicom -b 115200 -o -D /dev/ttyUSB0```
or
```screen /dev/ttyUSB1 115200```  "Ctrl-a \" to exit