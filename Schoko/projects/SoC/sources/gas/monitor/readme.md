# Description
A very minimal Monitor along the lines of Wozmon.

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
| **a** addr      | set working address | ] a 03ff |
| **w** value      | write to working address | ] w ff |
| **w** value value2 ...      | write to several locations starting at working address | ] w ff 44 |
| **r** type count      | read "count" of "type" memory locations starting at working address | ] r b 50 |

## Command "a"
**a** sets the working address that other commands reference.

## Command "w"
The **w** command can be given one or more values. The *width* of the value determines its type, for example, ff = byte, ffff = hword, ffffffff = word.

### Example 1
- ```00000001] w ff``` Writes a byte to address 0x00000001
- ```00400100] w ff ab 32``` Writes 3 bytes starting at working address
- ```00000001] w 1234abcd``` Writes a word at address 0x00000001. The address must be word aligned.

## Command "r"
The **r** command can be given a *type* and *count*. The *count* is how many *types* to read.

### Example 1
- ```00000001] r b 5``` Read 5 bytes starting at address 0x00000001
- ```00000001] r b 25``` Read 25 bytes starting at address 0x00000001
- ```00400100] r w 5``` Read 5 words starting at address 0x00400100

The output format of example #1 is:
```
00000001 01 02 03 04 05
```

The output format of example #2 is:
```
00000001 01 02 03 04 05 01 02 03
00000003 04 05 01 02 05 01 02 03
00000005 04 05 01 02 01 02 03 04
00000006 04
```

The output format of example #3 is:
```
00400100 01020304
00400101 04050102
00400102 04050102
00400103 01020304
00400104 01020304
```

## Command "r"
The **r** command accepts an Address. It then returns a value that should be displayed along side the command.

For example, entering: ```>r 3ff``` will cause a value to return, for example *4a*. The returned value should be appended: ```>r 3ff 4a```.

In this case entering:
```
Monitor 0.0.1 May 2023
>r 3ff
```
then hitting "return" will cause *4a* to return. It should be displayed


# Tasks
- [ ] Read a memory location
- [ ] Modify a memory location
- [ ] Dump a block of memory
- [ ] Upload a block of memory

# Example Monitors

## daveho hacks
- [daveho hacks](https://www.youtube.com/watch?v=e-CLhZKH1Es). This is a 6809 monitor at it starts 10:55 time mark.

## Commands
- **a** : Set working address
- **r** : read bytes
- **w** : write bytes
- **d** : download hex blob into memory
- **x** : e**X**ecute code at working address
- **s** : call subroutine working address

