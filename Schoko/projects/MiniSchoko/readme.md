# Description
This is a minimal version of Zucker for the Schoko. It has only the CPU, SDRAM and UART--nothing else.

The purpose is to isolate the SDRAM such that I can verify SDRAM actually works.

The CPU and SDRAM requires 50MHz clock.

# Memory map

```
BRAM    0           -> 0x00002b7f (11136-1)
SRAM    0x4000_0000 -> 0x41E84800
UART    0xf000_0000 -> ...
```

# UART
RTS/CTS are active low signals.

```host <--> module```

```
host  |   module
------------------
Tx    ->    Rx
/RTS  ->    /CTS
/CTS  <-    /RTS
Rx    ->    Tx
```

The host is able to tell the module it is ready to accept data over the UART by controlling its RTS output which signals to the module via the module's CTS input. Basically, the host's RTS line is high then the module is free to send data.

So the module will not send data unless CTS is asserted (low). Basically, an asserted RTS output tells the peer (aka module) that it is safe for the peer to send data.

The host can stop the module sending it data by taking its RTS high, which in turn takes the module’s CTS high. Likewise the module can stop the host sending data by taking its RTS high which takes the host’s CTS high.

# Firmware
This project will continue to use a simple $readmemh approach rather than ecpbram tool.

To build the firmware:
- cd to "gas" directory
- Modify makefile adjust paths to OUT2HEX and FIRMWARE_OUT

# Delay Counter
For a 0.5sec delay we need:

```
50MHz = 0.00002ms period
To count (0.00002) 25000 times = ~0.5ms
Thus multiply by 1000 to get 0.5s: 25000 * 1000 = 25000000
= 1_0111_1101_0111_1000_0100_0000 = 25bits = 0x017D7840

However, the cycle count of each instruction requires a divide by 8:
    addi t2, t2, -1     # 3 cycles
    bne t2, 2b          # 5 cycles
= 25000000 / 8 = 0x002FAF08

See https://github.com/YosysHQ/picorv32

So we need a 16 bit register.
```