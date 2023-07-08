.set CONSOLE_OUT, 0x10010000
.set CONSOLE_CONTROL, 0x10010008
.set CONSOLE_ENABLE, 1
.set CONSOLE_DISABLE, 0
.set BUFFER_SIZE, 32
.set HEX, 16
.set DEC, 10
.set BIN, 2
.set MACHINE_GLOBAL_INTERRUPT_ENABLE, 8
.set MACHINE_EACH_INTERRUPT_ENABLE, 0x888
.set INTERRUPT_HART0, 0x2000000
.set INTERRUPT_HART1, 0x2000004

.section .text, "ax", @progbits
.global boot
.type boot, @function
boot:
	la sp, stack_end		# Setup stack
	csrr a2, mhartid
	sll t0, a2, 10
	sub sp, sp, t0
	addi sp, sp, -BUFFER_SIZE

	la t0, trap
	csrw mtvec, t0			# Setup interrupt handler
	csrsi mstatus, MACHINE_GLOBAL_INTERRUPT_ENABLE
	li t0, MACHINE_EACH_INTERRUPT_ENABLE
	csrs mie, t0

	li t0, CONSOLE_CONTROL
	li t1, CONSOLE_ENABLE
	sw t1, (t0)

	bnez a2, halt			# Halt non zero harts

	la a0, hello
	jal puts

	la a0, mie1
	jal puts
	mv a0, sp
	li a1, BUFFER_SIZE
	csrr a2, mie
	li a3, BIN
	jal ultostr
	jal puts
	la a0, newline
	jal puts

	mv a0, sp
	csrr a2, mcycle
	li a3, DEC
	jal ultostr
	jal puts
	la a0, newline
	jal puts

	mv a0, sp
	li a2, 123456
	li a3, DEC
	jal ultostr
	jal puts
	la a0, newline
	jal puts

	addi sp, sp, BUFFER_SIZE

	li t0, INTERRUPT_HART1
	li t1, 1
	sw t1, (t0)

halt:
	wfi
#	la a0, woke_up
#	jal puts
	j halt

.type puts, @function
puts:
	li t0, CONSOLE_OUT
	li t1, 0
	mv t2, a0
1:	lb t3, (t2)
	addi t2, t2, 1
	beqz t3, 3f
2:	amoor.w t1, t3, (t0)
	bnez t1, 2b
	j 1b
3:	ret

.type ultostr, @function
ultostr:
	# convert unsigned long to string
	# a0: char *out
	# a1: size_t size
	# a2: unsigned long v
	# a3: unsigned long base
	mv t6, sp
	beqz a1, L_ultostr_exit		# exit on zero sized buffer
	addi t1, a1, -1			# decrement size to reserve space for '\0'
	beqz t1, L_ultostr_null		# if no space left, skip loops
	mv t2, a2
	li t3, 0			# character counter
	li t4, 10			# used to check if digit is less than 10

L_ultostr_loop_push:			# loop to convert the whole number to text
	remu t5, t2, a3			# least significant digit is calculated first
	divu t2, t2, a3
	bltu t5, t4, 1f
	addi t5, t5, 'A' - '0' - 10
1:	addi t5, t5, '0'
	addi sp, sp, -1
	sb t5, (sp)			# Store in stack to reverse later
	addi t3, t3, 1			# increment character counter
	bnez t2, L_ultostr_loop_push

	li t4, 0			# output loop counter
	mv t0, a0
	blt t3, t1, L_ultostr_loop_pop
	mv t3, t1			# truncate character counter to buffer size

L_ultostr_loop_pop:			# store in out buffer popping from stack
	lb t5, (sp)
	addi sp, sp, 1
	sb t5, (t0)
	addi t0, t0, 1
	addi t4, t4, 1
	blt t4, t3, L_ultostr_loop_pop

L_ultostr_null:
	li t5, 0			# '\0' terminator
	sb t5, (t0)

L_ultostr_exit:
	mv sp, t6
	ret

.type trap, @function
trap:
	la a0, trap1
	jal puts

	addi sp, sp, -BUFFER_SIZE
	mv a0, sp
	li a1, BUFFER_SIZE
	csrr a2, mcause
	li a3, HEX
	jal ultostr
	jal puts
	la a0, newline
	jal puts
	la a0, hart_id
	jal puts
	mv a0, sp
	csrr a2, mhartid
	jal ultostr
	jal puts
	la a0, trap2
	jal puts
	addi sp, sp, BUFFER_SIZE

	j halt

.section .data, "aw", @progbits
hello:	.string "Hello, world!\n"
newline:.string "\n"
trap1:	.string "Trap: "
trap2:	.string "\nHalting.\n"
mie1: .string "mie: "
woke_up: .string "Woke up, back to sleep.\n"
hart_id: .string "mhartid: "

.section .bss, "aw", @nobits
.skip 8192
stack_end: