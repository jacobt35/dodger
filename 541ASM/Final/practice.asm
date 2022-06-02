.data 0x10010000 		  # Start of data memory
board: .space 256		  # 8x8 board using int 1 for character here and 0 for nothing there 
				  # where M columns and N rows cell at row i column j is i*M+j-1
	###############################################
	#    0  1   2   3   4   5   6  7            	#			
	#  						#	 
	#    8  9  10  11  12   13  14  15     	#
	#                                             #
	#   16  17 18  19  20   21  21  23		#
	#                                             #
	#   24  25 26  27  28   29  30  31		#
	#                                             #
	#   32  33 34  35  36   37  38  39		#
	#                                             #
	#   40  41 42  43  44   45  46  47		#
	#                                             #
	#   48  49 50  51  52   53  54  55		#
	#                                             #
	#   56  57 58  59  60   61  62  63		#
	#                                             #
	#                                             #
	###############################################
													
p: .ascii "p"
.text 0x00400000                # Start of instruction memory
.globl main

# 40 columns   e ach bard column recieves 5 columns on screen
# 30 rows	each board row recives 4 rows on screen
# s0 is players x value  # factor of 4
# s1 is players accel value to move their character
# s2 is p character
# $s3 is players x value for screen	# 5 columns a piece
# $s4 is players y value for screen	# 3 rows a piece
# use duke logo from matlab and own carolina sprite :)

main:
	lui     $sp, 0x1001         # Initialize stack pointer to the 1024th location above start of data
    	ori     $sp, $sp, 0x1000    # top of the stack will be one word below
                                    # because $sp is decremented first.
    	addi    $fp, $sp, -4        # Set $fp to the start of main's stack frame
    	
    	#put player at middle of board in last row
    	lw  $s2, p		# going to use p to represent player
    	li $t1, 60 		# 60 is where we are starting player at
    	sll $t1, $t1, 2
    	sw $s2, board($t1)	# putting p into board
    	
 
    	li $s0, 240		# start at board pos 60  * 4 = 240 	
   	li $a0, 0		# character 0 will be my UNC logo
    	li $a1, 25		# column 25
    	li $a2, 24		# row 24 30/8 = 3.75 so round down to 3
  	li $s3, 25		# x value for screen
  	li $s4, 24		# y value for screen 
    	jal putChar_atXY
    	
game_loop:
	# definitly pause so player has time to react (.3 seconds?)
	# maybe condition on something to decrease time?
	# lets move the enemies
	li $t0, 0		# 64 places to look
move_char:
	# t0 = i
	# t1 = board[t0]
	# need to check where player is
	# at bottom of board need to remove from screen
	
	beq $t0, 256, move_player	# loop to go through them all and then once moved we check for player
	beq $t0, $s0, at_player	# we at the players position so we need to skip
	lw $t1, board($t0) 		# get correct position in board
	bne $zero, $t1, move_down	# go to proc to move sprite down
	addi $t0, $t0, 4
	j move_char
	
at_player:
	# just increment i and move on
	addi $t0, $t0, 4		
	j move_char
	
move_down:
# need to do t1 divided by 4 copy t1 into t2
# add 7
# multiply by 4 again
	add $t2, $t1, $zero		# copy t1 into t2
	srl $t2, $t2, 2			# divide by 4
	addi $t2, $t2, 7		# add by 7 cause we are zero indexed
	sll $t2, $t2, 2			# multiply by 4 for memory address
	lw $t1, board($t2)		# load a 1 into new memory address
	lw $zero, board($t1)		# put a zero in old memory address
	# now we move character on our screen black then duke
	# jal putchar need y position of board and then put black square in previous position
	beq $t2, $s0, collison	 # collison
	addi $t0, $t0, 4		
	j move_char
move_player:
	# get accel value of y (left to right)
	jal get_accelY
	add $s1, $v0, $zero		# put x accel into s1
	# based on accel decide how to move
	# need a buffer so we are not moving all the time
	# butch of comparisons
	# 120 = 0x0078
	# 210 = 0x00D2
	# 300 = 0x012C
	# 390 = 0x186
move_right_1:
	blt $s1, 0x0032, no_move	# accel to small so we do not move
	bgt $s1, 0x0078, move_right_2
	# steps to move by 1
	#set players X to 0 in board
	add $t0, $zero, $s0		# players pos into t0
	lw $zero, board($t0)		# pos now 0
	add $s0, $s0, 4			# adding 4 to board pos (1 board space)
	# need to check if we are at edge of screen? new proc? if so set to 252
	addi $t0, $zero, 1
	lw $t0, board($s0)		# adding 1 in new part of board 
	# putting black square
	li $a0, 2,			# 2 is our charcode for black square
	add $a1, $s3, $zero			# x coord
	add $a2, $s4, $zero			# y coord
	jal putChar_atXY
	# getting new screen coords
	addi $s3, $s3, 5			# adding 5 to our x coord
	li $a0, 0			# 0 is unc logo
	add $a1, $s3, $zero			# s3 is x coord
	add $a2, $s4, $zero			# s4 is y coord
	jal putChar_atXY		# put unc logo at new address
move_right_2:	
	bgt $s1, 0x00D2, move_left_1
	# steps for moving by 2
	#set players X to 0 in board
	add $t0, $zero, $s0		# players pos into t0
	lw $zero, board($t0)		# pos now 0
	add $s0, $s0, 8			# adding 8 to board pos move two spaces
	# need to check if we are at edge of screen? new proc? if so set to 252
	addi $t0, $zero, 1
	lw $t0, board($s0)		# adding 1 in new part of board 
	#jal putchar 0			need to find screen adress based on location on board
move_left_1:
	bgt $s1, 0x12C, move_left_2
	# steps for moving by 3
	#set players X to 0 in board
	add $t0, $zero, $s0		# players pos into t0
	lw $zero, board($t0)		# pos now 0
	add $s0, $s0, -4			# adding -4 to board pos (1 left)
	# need to check if we are at edge of screen? new proc? if so set to 252
	addi $t0, $zero, 1
	lw $t0, board($s0)		# adding 1 in new part of board 
	#jal putchar 0			need to find screen adress based on location on board
move_left_2:
	# if were here that means fast
	#steps for moving by 4
	add $t0, $zero, $s0		# players pos into t0
	lw $zero, board($t0)		# pos now 0
	add $s0, $s0, -8			# adding -8 to board pos (2 left)
	# need to check if we are at edge of screen? new proc? if so set to 252
	addi $t0, $zero, 1
	lw $t0, board($s0)		# adding 1 in new part of board 
	#jal putchar 0			need to find screen adress based on location on board
no_move:
	j add_enemies		# no move accel value to small
	
# need to add new enemies now or maybe find a way to tell how much time has passed?
add_enemies:
	# keep a count in a register and every so often lower it
	j game_loop	
	
collison: 
	# player has been hit
	# play a sound and end game
	
	
.include "procs_board.asm"
#.include "procs_mars.asm"
	
	


