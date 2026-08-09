	.text
	.global main
main:
	li	a0, 1
	lla	a1, _end

loop:	sw	a0, 0(a1)
	lw	t0, 0(a1)
	addi	a1, a1, 4

	slli	a0, a0, 1
	bnez	a0, loop

	ret
