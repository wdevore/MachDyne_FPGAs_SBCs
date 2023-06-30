# Description
A very minimal Monitor along the lines of Wozmon.

# Development
There is two areas you need to run tools from:

## Programs to load
Via the monitor's "u" command. You write your code in assembly and then assemble it with the two make targets:
1) make
2) make out2verilog

This produces a *.hex* file that can be uploaded via the Monitor.

The folder from ```/.../Hardware/MachDyne_FPGAs_SBCs/Schoko/projects/SoC/sources/programs``` should have sub folders for each program. Each program has a *.s* file and *.ld* file.

## Building the Monitor
1) cd to ```.../Hardware/MachDyne_FPGAs_SBCs/Schoko/projects/SoC/sources/gas/monitor``` and run *make*
2) cd to ```.../Hardware/MachDyne_FPGAs_SBCs/Schoko/projects/SoC/soc_phase2``` and run *make*
3) In the Monitor type the **u** command. This makes the Monitor wait for bytes.
4) cd to ```.../Hardware/MachDyne_FPGAs_SBCs/Schoko/projects/SoC/sources/uploader``` and run *go run . /media/RAMDisk/filename.hex*

# Requirements
- Read a memory location
- Modify a memory location
- Dump a block of memory
- Upload a block of memory

# Description
When the monitor first boots it displays "Monitor 0.0.1 May 2023" and displays a "]". For example:
```
Monitor 0.0.1 May 2023
00000000]
```

# Commands
| Command | Description            | Example  |
|   ---   |   ---                  |  ---     |
| **a(w or b)** addr      | set working address | ] aw 03ff |
| **w(w or b)** value      | write to working address | ] wb ff |
| **w(w or b)** value value2 ...      | write to several locations starting at working address | ] wb ff 44 ab cd |
| **r(w or b)** count      | read "count" of "type" memory locations starting at working address | ] rb 50 |
| **r(w or b)** lines      | read "lines" where each line shows 3 words of "type" memory locations starting at working address | ] rb 50 |
| **x**       | execute program at working address | ] x |
| **u**       | initiates a program upload into working address | ] u |

### Example 1
- ```00000001] wb ff``` Writes a byte to address 0x00000001
- ```00400100] wb ff ab 32``` Writes 3 bytes starting at working address
- ```00000001] ww 1234abcd``` Writes a word at address 0x00000001. The address must be word aligned.

### Example 1
- ```00000001] rb 5``` Read 5 bytes starting at address 0x00000001
- ```00000001] rb 25``` Read 25 bytes starting at address 0x00000001
- ```00400100] rw 5``` Read 5 words starting at address 0x00400100

The output format of example #1 is:
```
00000001: 01 02 03 04 05  .....
```

The output format of example #2 is:
```
00000001: 01 02 03 04 05 01 02 03  ........
00000003: 04 05 01 02 05 01 02 03  ........
00000005: 04 05 01 02 01 02 03 04  ........
```

The output format of ```rw 5``` is:
```
00400100: 01020304  ....
00400101: 04050102  ....
00400102: 04050102  ....
00400103: 01020304  ....
00400104: 01020304  ....
```

# Tasks
- [x] Read a memory location
- [x] Modify a memory location
- [x] Dump a block of memory
- [ ] Upload a block of memory

s0 and t6 don't seem to work??

# Example Monitors

## daveho hacks
- [daveho hacks](https://www.youtube.com/watch?v=e-CLhZKH1Es). This is a 6809 monitor at it starts 10:55 time mark.

