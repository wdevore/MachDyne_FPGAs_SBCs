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
| **r** addr      | read a memory location | >R 03ff |
| **r** addrS:AddrE      | read a memory range | >R 03ff:0500 |
| **r** addr;size      | read a memory range | >R 03ff;50 |
| **w** addr value      | write a memory location | >W 03ff ff |
| **w** addr value value2 ...      | write several locations | >W 03ff ff 44 36 |
| **d** start-addr row-count     | dump a memory block  | >D 03ff 50 |
| **u** | upload a block of bytes | >U |

## Command "R"
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

