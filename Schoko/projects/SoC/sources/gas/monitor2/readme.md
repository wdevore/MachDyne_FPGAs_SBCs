# Description
**Monitor2** differs from **Monitor** in that it has size optimized to gain back BRAM. It makes heavier use of registers.

Note: See *monitor* folder details about *programs* and build instructions.

# Memory
The ECP5-45F has:
```
Embedded RAM: 1944000 = 243000B = 60750 Words
D-RAM: 351Kb = 43875B
```
# Code notes:


## Building the Soc and loading micro programs
1) cd to ```.../Hardware/MachDyne_FPGAs_SBCs/Schoko/projects/SoC/sources/gas/monitor``` and run *make*
2) cd to ```.../Hardware/MachDyne_FPGAs_SBCs/Schoko/projects/SoC/soc_phase2``` and run *make*
3) In the Monitor type the **u** command. This makes the Monitor wait for bytes.
4) cd to ```.../Hardware/MachDyne_FPGAs_SBCs/Schoko/projects/SoC/sources/uploader``` and run *go run . /media/RAMDisk/filename.hex*


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


