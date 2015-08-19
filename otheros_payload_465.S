/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

.set STACK_SIZE,						0x100
.set STACK_LR,							(STACK_SIZE + 0x10)
.set STACK_R25,							(STACK_SIZE - 1 * 0x8)
.set STACK_R26,							(STACK_SIZE - 2 * 0x8)
.set STACK_R27,							(STACK_SIZE - 3 * 0x8)
.set STACK_R28,							(STACK_SIZE - 4 * 0x8)
.set STACK_R29,							(STACK_SIZE - 5 * 0x8)
.set STACK_R30,							(STACK_SIZE - 6 * 0x8)
.set STACK_R31,							(STACK_SIZE - 7 * 0x8)
.set STACK_PATH,						(STACK_SIZE - 8 * 0x8)
.set STACK_LAID,						(STACK_SIZE - 9 * 0x8)
.set STACK_LPAR_ID,						(STACK_SIZE - 10 * 0x8)
.set STACK_LPAR_MEM,						(STACK_SIZE - 11 * 0x8)
.set STACK_REPO_NODE_KEY4,					(STACK_SIZE - 12 * 0x8)
.set STACK_REPO_NODE_KEY3,					(STACK_SIZE - 13 * 0x8)
.set STACK_REPO_NODE_KEY2,					(STACK_SIZE - 14 * 0x8)
.set STACK_REPO_NODE_KEY1,					(STACK_SIZE - 15 * 0x8)
.set STACK_REPO_NODE_VAL2,					(STACK_SIZE - 16 * 0x8)
.set STACK_REPO_NODE_VAL1,					(STACK_SIZE - 17 * 0x8)

.set SUB_SLL_LOAD_LV2,						0x80000EA4		/* sll_load_lv2 */
.set SUB_MMAP_LPAR_MEM,						0x80002714
.set SUB_OPEN,							0x80014530		/* syscall 0x7 */
.set SUB_CLOSE,							0x8001456C		/* syscall 0x8 */
.set SUB_READ,							0x800145A8		/* syscall 0x9 */
.set SUB_MUNMAP,						0x800146A8		/* syscall 0x19 */
.set SUB_BSET,							0x80000278
.set SUB_BCOPY,							0x80000254
.set SUB_STRNCMP,						0x800141D0
.set SUB_CREATE_REPO_NODE,					0x80013778		/* syscall 0x100C0 */
.set SUB_GET_REPO_NODE_VAL,					0x800137C0 		/* syscall 0x100C1 */
.set SUB_STOR_MGR_DRIVE_AUTH,					0x80002D50		/* storage manager 0x5004 service */

#define BL(sub_addr)						\
	li %r30, 0;						\
	oris %r30, %r30, (sub_addr >> 16);			\
	ori %r30, %r30, (sub_addr & 0xFFFF);			\
	mtctr %r30;						\
	bctrl

.set OS_AREA_SIZE,						(4 * 0x200)
.set HEADER_MAGIC_SIZE,						0x10
.set OS_AREA_HEADER_VERSION_OFFSET,				0x10
.set HEADER_VERSION,						0x1
.set OS_AREA_HEADER_LDR_FORMAT_OFFSET,				0x20
.set OS_AREA_HEADER_LDR_FORMAT_RAW,				0x0
.set OS_AREA_HEADER_LDR_SIZE_OFFSET,				0x24
.set OS_AREA_PARAMS_BOOT_FLAG_OFFSET,				0x200
.set OS_AREA_PARAMS_BOOT_FLAG_GAME_OS,				0x0

.set CACHE_LINE_SIZE,						0x80

.set FD_ERROR,							0x10
.set HEADER_ERROR,						0x14
.set SKIP_ERROR,						0xF

#define LWZ_DATA(reg, data_addr)				lwz reg, data_addr(%r31)
#define LD_DATA(reg, data_addr)					ld reg, data_addr(%r31)
#define LD_DATA_PTR(reg, data_addr)				addi reg, %r31, data_addr - sll_load_lv2

/*
 * %r3 - path
 * %r4 - laid
 * %r5 - lpar id
 *
 * %r25 - volatile
 * %r26 - OtherOS bootloader load address
 * %r27 - return value
 * %r28 - size of /dev/rflash_lx
 * %r29 - file descriptor of /dev/rflash_lx
 * %r30 - reserved for function calls
 * %r31 - reserved for data accesses
 */
.globl sll_load_lv2
sll_load_lv2:

	stdu %r1, -STACK_SIZE(%r1)
	mflr %r0
	std %r0, STACK_LR(%r1)
	std %r25, STACK_R25(%r1)
	std %r26, STACK_R26(%r1)
	std %r27, STACK_R27(%r1)
	std %r28, STACK_R28(%r1)
	std %r29, STACK_R29(%r1)
	std %r30, STACK_R30(%r1)
	std %r31, STACK_R31(%r1)
	std %r3, STACK_PATH(%r1)
	std %r4, STACK_LAID(%r1)
	std %r5, STACK_LPAR_ID(%r1)

	bl 1f

1:

	mflr %r31
	addi %r31, %r31, (sll_load_lv2 - 1b)

	/* check update status */

	LD_DATA(%r0, repo_node_key_ss)
	std %r0, STACK_REPO_NODE_KEY1(%r1)
	LD_DATA(%r0, repo_node_key_param)
	std %r0, STACK_REPO_NODE_KEY2(%r1)
	LD_DATA(%r0, repo_node_key_update)
	std %r0, STACK_REPO_NODE_KEY3(%r1)
	LD_DATA(%r0, repo_node_key_status)
	std %r0, STACK_REPO_NODE_KEY4(%r1)
	li %r0, 0
	std %r0, STACK_REPO_NODE_VAL1(%r1)
	std %r0, STACK_REPO_NODE_VAL2(%r1)
	li %r3, 1
	addi %r4, %r1, STACK_REPO_NODE_KEY1
	addi %r5, %r1, STACK_REPO_NODE_VAL1
	BL(SUB_GET_REPO_NODE_VAL)
	cmpdi %cr7, %r3, 0
	bne %cr7, check_product_mode

	/* skip OtherOS booting when update is in progress */

	ld %r0, STACK_REPO_NODE_VAL1(%r1)
	rldicl %r0, %r0, 0, 56
	cmpwi %cr7, %r0, 0xFF
	li %r27, SKIP_ERROR
	bne %cr7, done

check_product_mode:

	/* check product mode */

	LD_DATA(%r0, repo_node_key_ss)
	std %r0, STACK_REPO_NODE_KEY1(%r1)
	LD_DATA(%r0, repo_node_key_param)
	std %r0, STACK_REPO_NODE_KEY2(%r1)
	LD_DATA(%r0, repo_node_key_product)
	std %r0, STACK_REPO_NODE_KEY3(%r1)
	LD_DATA(%r0, repo_node_key_mode)
	std %r0, STACK_REPO_NODE_KEY4(%r1)
	li %r0, 0
	std %r0, STACK_REPO_NODE_VAL1(%r1)
	std %r0, STACK_REPO_NODE_VAL2(%r1)
	li %r3, 1
	addi %r4, %r1, STACK_REPO_NODE_KEY1
	addi %r5, %r1, STACK_REPO_NODE_VAL1
	BL(SUB_GET_REPO_NODE_VAL)
	cmpdi %cr7, %r3, 0
	bne %cr7, check_recover_mode

	/* skip OtherOS booting when product mode is on */

	ld %r0, STACK_REPO_NODE_VAL1(%r1)
	rldicl %r0, %r0, 0, 56
	cmpwi %cr7, %r0, 0xFF
	li %r27, SKIP_ERROR
	bne %cr7, done

check_recover_mode:

	/* check recover mode */

	LD_DATA(%r0, repo_node_key_ss)
	std %r0, STACK_REPO_NODE_KEY1(%r1)
	LD_DATA(%r0, repo_node_key_param)
	std %r0, STACK_REPO_NODE_KEY2(%r1)
	LD_DATA(%r0, repo_node_key_recover)
	std %r0, STACK_REPO_NODE_KEY3(%r1)
	LD_DATA(%r0, repo_node_key_mode)
	std %r0, STACK_REPO_NODE_KEY4(%r1)
	li %r0, 0
	std %r0, STACK_REPO_NODE_VAL1(%r1)
	std %r0, STACK_REPO_NODE_VAL2(%r1)
	li %r3, 1
	addi %r4, %r1, STACK_REPO_NODE_KEY1
	addi %r5, %r1, STACK_REPO_NODE_VAL1
	BL(SUB_GET_REPO_NODE_VAL)
	cmpdi %cr7, %r3, 0
	bne %cr7, check_hddcopy_mode

	/* skip OtherOS booting when recover mode is on */

	ld %r0, STACK_REPO_NODE_VAL1(%r1)
	rldicl %r0, %r0, 0, 56
	cmpwi %cr7, %r0, 0xFF
	li %r27, SKIP_ERROR
	bne %cr7, done

check_hddcopy_mode:

	/* check hdd copy mode */

	LD_DATA(%r0, repo_node_key_ss)
	std %r0, STACK_REPO_NODE_KEY1(%r1)
	LD_DATA(%r0, repo_node_key_param)
	std %r0, STACK_REPO_NODE_KEY2(%r1)
	LD_DATA(%r0, repo_node_key_hddcopy)
	std %r0, STACK_REPO_NODE_KEY3(%r1)
	LD_DATA(%r0, repo_node_key_mode)
	std %r0, STACK_REPO_NODE_KEY4(%r1)
	li %r0, 0
	std %r0, STACK_REPO_NODE_VAL1(%r1)
	std %r0, STACK_REPO_NODE_VAL2(%r1)
	li %r3, 1
	addi %r4, %r1, STACK_REPO_NODE_KEY1
	addi %r5, %r1, STACK_REPO_NODE_VAL1
	BL(SUB_GET_REPO_NODE_VAL)
	cmpdi %cr7, %r3, 0
	bne %cr7, map_lpar_mem

	/* skip OtherOS booting when hdd copy mode is on */

	ld %r0, STACK_REPO_NODE_VAL1(%r1)
	rldicl %r0, %r0, 0, 56
	cmpwi %cr7, %r0, 0xFF
	li %r27, SKIP_ERROR
	bne %cr7, done

map_lpar_mem:

	/* map lpar memory */

	ld %r3, STACK_LPAR_ID(%r1)
	li %r4, 0
	LD_DATA(%r26, bootloader_load_addr)
	LD_DATA(%r28, dev_rflash_lx_size)
	add %r5, %r26, %r28
	addi %r6, %r1, STACK_LPAR_MEM
	BL(SUB_MMAP_LPAR_MEM)
	cmpwi %cr7, %r3, 0
	mr %r27, %r3
	bne %cr7, done

	/* zero out lpar memory */

	ld %r3, STACK_LPAR_MEM(%r1)
	li %r4, 0
	mr %r5, %r28
	BL(SUB_BSET)

	/* open /dev/rflash_lx where OtherOS bootloader is stored */

	LD_DATA_PTR(%r3, dev_rflash_lx)
	li %r4, 0
	li %r27, FD_ERROR
	BL(SUB_OPEN)
	cmpwi %cr7, %r3, 0
	mr %r29, %r3
	blt %cr7, bad1

	/* read os area */

	extsw %r3, %r29
	ld %r4, STACK_LPAR_MEM(%r1)
	li %r25, OS_AREA_SIZE
	mr %r5, %r25
	li %r27, FD_ERROR
	BL(SUB_READ)
	cmpd %cr7, %r3, %r25
	bne %cr7, bad2

	/* check header magic */

	li %r27, HEADER_ERROR

	LD_DATA_PTR(%r3, header_magic)
	ld %r4, STACK_LPAR_MEM(%r1)
	li %r5, HEADER_MAGIC_SIZE
	BL(SUB_STRNCMP)
	cmpdi %cr7, %r3, 0
	bne %cr7, bad2

	/* check header version */

	ld %r5, STACK_LPAR_MEM(%r1)
	lwz %r25, OS_AREA_HEADER_VERSION_OFFSET(%r5)
	cmpwi %cr7, %r25, HEADER_VERSION
	bne %cr7, bad2

	/* check loader format */

	ld %r5, STACK_LPAR_MEM(%r1)
	lwz %r25, OS_AREA_HEADER_LDR_FORMAT_OFFSET(%r5)
	cmpwi %cr7, %r25, OS_AREA_HEADER_LDR_FORMAT_RAW
	bne %cr7, bad2

	/* check boot flag */

	ld %r5, STACK_LPAR_MEM(%r1)
	lwz %r25, OS_AREA_PARAMS_BOOT_FLAG_OFFSET(%r5)
	cmpwi %cr7, %r25, OS_AREA_PARAMS_BOOT_FLAG_GAME_OS
	beq %cr7, bad2

	/* read OtherOS bootloader size from header */

	ld %r5, STACK_LPAR_MEM(%r1)
	lwz %r25, OS_AREA_HEADER_LDR_SIZE_OFFSET(%r5)
	cmpd %cr7, %r25, %r28
	bgt %cr7, bad2

	/* read OtherOS bootloader to lpar memory */

	extsw %r3, %r29
	ld %r4, STACK_LPAR_MEM(%r1)
	mr %r5, %r25
	li %r27, FD_ERROR
	BL(SUB_READ)
	cmpd %cr7, %r3, %r25
	bne %cr7, bad2

	/* create repo node ios.ata.region0.access in LPAR 1 which enables access to all storage regions */

	LD_DATA(%r0, repo_node_key_ios)
	std %r0, STACK_REPO_NODE_KEY1(%r1)
	LD_DATA(%r0, repo_node_key_ata)
	std %r0, STACK_REPO_NODE_KEY2(%r1)
	LD_DATA(%r0, repo_node_key_region0)
	std %r0, STACK_REPO_NODE_KEY3(%r1)
	LD_DATA(%r0, repo_node_key_access)
	std %r0, STACK_REPO_NODE_KEY4(%r1)
	li %r0, 0
	std %r0, STACK_REPO_NODE_VAL1(%r1)
	std %r0, STACK_REPO_NODE_VAL2(%r1)
	li %r3, 1
	addi %r4, %r1, STACK_REPO_NODE_KEY1
	addi %r5, %r1, STACK_REPO_NODE_VAL1
	BL(SUB_CREATE_REPO_NODE)

	/* don't check return value */

	/* authenticate BD drive */

	li %r3, 0x29
	BL(SUB_STOR_MGR_DRIVE_AUTH)

	/* don't check return value */

	/* flush data cache */

	li %r9, 0
	b 2f

1:

	ld %r0, STACK_LPAR_MEM(%r1)
	add %r0, %r9, %r0
	dcbst %r0, %r0
	addi %r9, %r9, CACHE_LINE_SIZE

2:

	cmpd %cr7, %r9, %r28
	blt %cr7, 1b

	sync

	/* flush code cache */

	li %r9, 0
	b 2f

1:

	ld %r0, STACK_LPAR_MEM(%r1)
	add %r0, %r9, %r0
	icbi %r0, %r0
	addi %r9, %r9, CACHE_LINE_SIZE

2:

	cmpd %cr7, %r9, %r28
	blt %cr7, 1b

	isync

success:

	li %r27, 0

bad2:

	/* close /dev/rflash_lx */

	extsw %r3, %r29
	BL(SUB_CLOSE)

bad1:

	/* unmap lpar memory */

	ld %r3, STACK_LPAR_MEM(%r1)
	add %r4, %r26, %r28
	BL(SUB_MUNMAP)

done:

	rldicl %r3, %r27, 0, 32

	ld %r0, STACK_LR(%r1)
	ld %r25, STACK_R25(%r1)
	ld %r26, STACK_R26(%r1)
	ld %r27, STACK_R27(%r1)
	ld %r28, STACK_R28(%r1)
	ld %r29, STACK_R29(%r1)
	ld %r30, STACK_R30(%r1)
	ld %r31, STACK_R31(%r1)

	cmpwi %cr7, %r3, 0
	beq %cr7, return

boot_gameos:

	ld %r3, STACK_PATH(%r1)
	ld %r4, STACK_LAID(%r1)
	ld %r5, STACK_LPAR_ID(%r1)

	addi %r1, %r1, STACK_SIZE
	mtlr %r0

	li %r6, 0
	oris %r6, %r6, (SUB_SLL_LOAD_LV2 >> 16)
	ori %r6, %r6, (SUB_SLL_LOAD_LV2 & 0xFFFF)
	mtctr %r6
	bctr

	/* NOT REACHED */

return:

	addi %r1, %r1, STACK_SIZE
	mtlr %r0
	blr

/* read-only data */

data_start:

bootloader_load_addr:
	.quad 0x0000000000000000

header_magic:
	.asciz "cell_ext_os_area"

.align 4

dev_rflash_lx_size:
	.quad (0xC000 * 0x200) /* 0xC000 sectors of size 0x200 */

dev_rflash_lx:
	.asciz "/dev/rflash_lx"

.align 4

repo_node_key_ss:
	.quad 0x0000000073730000

repo_node_key_param:
	.quad 0x706172616D000000

repo_node_key_update:
	.quad 0x7570646174650000

repo_node_key_status:
	.quad 0x7374617475730000

repo_node_key_product:
	.quad 0x70726F6475637400

repo_node_key_mode:
	.quad 0x6D6F646500000000

repo_node_key_recover:
	.quad 0x7265636F76657200

repo_node_key_hddcopy:
	.quad 0x686464636F707900

repo_node_key_ios:
	.quad 0x00000000696F7300

repo_node_key_ata:
	.quad 0x6174610000000000

repo_node_key_region0:
	.quad 0x726567696F6E3000

repo_node_key_access:
	.quad 0x6163636573730000

data_end:
