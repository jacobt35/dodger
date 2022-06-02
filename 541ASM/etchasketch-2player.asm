#############################################################################################
#
# Montek Singh
# COMP 541 Final Projects
# Nov 2, 2020
#
# This is a MIPS program that tests the MIPS processor and the VGA display,
# using a very simple animation.
#
# This program assumes the memory-IO map introduced in class specifically for the final
# projects.  In MARS, please select:  Settings ==> Memory Configuration ==> Default.
#
#############################################################################################

.data 0x10010000 			# Start of data memory
a_sqr:	.space 4
a:	.word 3

.text 0x00400000                # Start of instruction memory
.globl main

main:
    lui     $sp, 0x1001         # Initialize stack pointer to the 1024th location above start of data
    ori     $sp, $sp, 0x1000    # top of the stack will be one word below
                                #   because $sp is decremented first.
    addi    $fp, $sp, -4        # Set $fp to the start of main's stack frame
	
	
	
	###############################################
	# ANIMATE character on screen                 #
	#                                             #
	# To eliminate pauses (for Vivado simulation) #
	# replace the two "jal pause" instructions    #
	# by nops.                                    #
	###############################################

	
	li $s1, 10			# initialize to middle screen col (X=20)
	li $s2, 15			# initialize to middle screen row (Y=15)
	li $s3, 30
	li $s4, 15

animate_loop:	

	li	$a0, 0			# draw player 1 here
	move $a1, $s1
	move $a2, $s2
	jal	putChar_atXY 		# $a0 is char, $a1 is X, $a2 is Y
	
	li	$a0, 1			# draw player 2 here
	move $a1, $s3
	move $a2, $s4
	jal	putChar_atXY 		# $a0 is char, $a1 is X, $a2 is Y
	
	jal	get_accelX		# get front to back board tilt angle
	sll	$a0, $v0, 12		# multiply by 2^12
	jal	put_sound		# create sound with that as period
	
	jal	get_accelY		# get left to right tilt angle
	srl	$v0, $v0, 5		# keep leftmost 4 bits out of 9
	li	$a0, 1
	sllv $a0, $a0, $v0		# calculate 2^v0 (one hot pattern, 2^0 to 2^15)
	jal	put_leds		# one LED will be lit
	
	addi	$a0, $0, 10
	jal	pause_and_getkey_2player     # responsive 2-player input during 0.1s pause

	# For a 1-player game, simply comment the line above and use the line below instead.
	# jal pause_and_getkey             # responsive 1-player input during 0.1s pause

###########################################################################################
# NOTE: There are two arrays of valid keys defined in the get_key/get_key2 procedures.    #
#       The first array defines the keys for get_key (for PLAYER 1), and the second       #
#       array does so for get_key2 (for PLAYER 2).                                        #
#                                                                                         #
#       In the version for deployment on the boards (procs_board.asm), please list the    #
#       appropriate scancodes for valid keys (e.g., 0x1D, which corresponds to ‘w’).      #
#       In the version for simulating in MARS, please list as a character (e.g., ‘w’).    #
###########################################################################################


	move	$s5, $v0                # save keys in $s registers to protect them from called procedures
	move	$s6, $v1

PLAYER1:
	beq	$s5, $0, PLAYER2	# 0 means no valid key

	move $a0, $s5
	move $a1, $s1
	move $a2, $s2
	jal	move_player             # call move_player with PLAYER 1’s position and key
	move $s1, $v0
	move $s2, $v1

PLAYER2:
	beq	$s6, $0, animate_loop	# 0 means no valid key
	
	move $a0, $s6
	move $a1, $s3
	move $a2, $s4
	jal	move_player             # call move_player with PLAYER 2’s position and key
	move $s3, $v0
	move $s4, $v1

	j	animate_loop            # go back to start of animation loop
	
					
	###############################
	# END using infinite loop     #
	###############################
end:
	j	end          	# infinite loop "trap" because we don't have syscalls to exit


######## END OF MAIN #################################################################################

.text

#####################################
# procedure move_player
# $a0:  key
# $a1:  x coord
# $a2:  y coord
#
# return values:
# $v0:  new x coord
# $v1:  new y coord
#####################################

move_player:
    addi    $sp, $sp, -8        # Make room on stack for saving $ra and $fp
    sw      $ra, 4($sp)         # Save $ra
    sw      $fp, 0($sp)         # Save $fp
    addi    $fp, $sp, 4         # Set $fp to the start of proc1's stack frame
                    
	move $v0, $a1
	move $v1, $a2

key1:
	bne	$a0, 1, key2
	addi $v0, $v0, -1 		# move left
	slt	$1, $v0, $0		# make sure X >= 0
	beq	$1, $0, done_moving
	li	$v0, 0			# else, set X to 0
	j	done_moving

key2:
	bne	$a0, 2, key3
	addi $v0, $v0, 1 		# move right
	slti $1, $v0, 40		# make sure X < 40
	bne	$1, $0, done_moving
	li	$v0, 39			# else, set X to 39
	j	done_moving

key3:
	bne	$a0, 3, key4
	addi $v1, $v1, -1 		# move up
	slt	$1, $v1, $0		# make sure Y >= 0
	beq	$1, $0, done_moving
	li	$v1, 0			# else, set Y to 0
	j	done_moving

key4:
	bne	$a0, 4, done_moving # read key again
	addi $v1, $v1, 1 		# move down
	slti $1, $v1, 30		# make sure Y < 30
	bne	$1, $0, done_moving
	li	$v1, 29			# else, set Y to 29

done_moving:

return_from_move_player:
    addi    $sp, $fp, 4     # Restore $sp
    lw      $ra, 0($fp)     # Restore $ra
    lw      $fp, -4($fp)    # Restore $fp
    jr      $ra             # Return from procedure

# =============================================================



#.include "procs_board.asm"               # Use this line for board implementation
#.include "procs_mars.asm"                # Use this line for simulation in MARS
