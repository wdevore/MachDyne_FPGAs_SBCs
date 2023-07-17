# Description
Provides an interface to Schoko's SDRAM memory (32MB). The interface is designed to connect to the SoC much like the UART component.

# Design
Use a burst = 2. This will read two 16 bit half-words.

**Note: check on endianess!!!!**

The first read stores the value in the upper half-word of the output register.

The second read concatinates the 16 bit half-word to the lower half-word.

# Notes
The expression "|nnn" is OR'ing all the bits together and when used in a expression results in a zero value test.
```
assign F = (BCD > 4'd0) & (BCD < 4'd6);
Equals:
assign F = |BCD & (BCD < 4'd6);
```