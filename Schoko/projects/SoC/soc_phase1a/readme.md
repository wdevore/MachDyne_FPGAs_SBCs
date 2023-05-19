# Description
*Phase 1a* is about sending a "Ok" string to a client (minicom in this instance). Eventually the later phases will communicate with a **Go** client.

The simulation tests the merging of UART component and Femto. Port A has already been tested.

# Tasks
- [x] Write firmware to send "Ok" string and poll for busy flag between each character
- [x] Build simulation
- [x] Build synth

# Issues
When reading the rx_buffer the SoC needs enough time to read the buf.