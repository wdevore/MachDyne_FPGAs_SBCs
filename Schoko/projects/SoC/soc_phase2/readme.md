# Description
*Phase 2* integrates GNU Gas assembler for writing a basic Monitor. This does not include a bootloader, just a barebones monitor.

# Requirements
- Read a memory location
- Modify a memory location
- Dump a block of memory
- Upload a block of memory

# Description
When the monitor first boots it displays "Monitor 0.0.1 May 2023" and displays a ">". For example:
```
Monitor 0.0.1 May 2023
>
```

# Commands
| Command | Description            | Example  |
|   ---   |   ---                  |  ---     |
| **r** addr      | read a memory location | >R 03ff |
| **w** addr value      | write a memory location | >W 03ff ff |
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
