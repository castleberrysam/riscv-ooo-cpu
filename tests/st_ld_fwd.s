	.text
	.global main
main:
	li	a0, 128
	li	a1, 0x20000000

loop:	sw	t0, 0(a1)
	lw	t1, 0(a1)
	addi	a1, a1, 4

	addi	a0, a0, -1
	bgtz	a0, loop

	ret
