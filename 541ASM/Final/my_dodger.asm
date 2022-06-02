.data 0x10010000
board: .space 256		  # 8x8 board using int 1 for character here and 0 for nothing there 
				  # where M columns and N rows cell at row i column j is i*M+j-1
board_copy: .space 256		  # copy of board where we mark if cell -8 has already moved
	###############################################
	#    0  1   2   3   4   5   6  7            	#			
	#  						#	 
	#    8  9  10  11  12   13  14  15     	#
	#                                             #
	#   16  17 18  19  20   21  22  23		#
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
# $s5 is round 
# $s6 is amount of pieces moved
# use duke logo from matlab and own carolina sprite :)

# need to see why levels not showing up right
main:
	lui     $sp, 0x1001         # Initialize stack pointer to the 1024th location above start of data
    	ori     $sp, $sp, 0x1000    # top of the stack will be one word below
                                    # because $sp is decremented first.
    	addi    $fp, $sp, -4        # Set $fp to the start of main's stack frame
    	
    	#put player at middle of board in last row
    	lw  $s2, p		# going to use p to represent player
    	li $t1, 60		# 60 is where we are starting player at
    	sll $t1, $t1, 2
    	sw $s2, board($t1)	# putting p into board
    	 	

    	#load in a single enemy 
    	li $t0, 1
    	li $t1, 16
    	#li $t1, 220
    	sw $t0, board($t1)
    	li $a0, 1
    	li $a1, 20		# 20th column
    	li $a2, 3		# 3rd row
    	jal putChar_atXY
    	   	  	 
    	li $s0, 240		# start at board pos 60  * 4 = 240 	
   	li $a0, 0		# character 0 will be my UNC logo
    	li $a1, 20		# column 20
    	li $a2, 24		# row 24 30/8 = 3.75 so round down to 3
  	li $s3, 20		# x value for screen 20
  	li $s4, 24		# y value for screen 
  	li $s5, 1
    	jal putChar_atXY
    	
    	
game_loop:
	# definitly pause so player has time to react (.3 seconds?)
	# maybe condition on something to decrease time?
	# lets move the enemies
	li $a0, 200
	jal pause		#pause for .2 seconds
	li $t0, 0		# 64 places to look
move_char:
	# t0 = i
	# t1 = board[t0]
	# need to check where player is
	# at bottom of board need to remove from screen
	beq $t0, 256, move_player	# loop to go through them all and then once moved we check for player
	beq $t0, $s0, at_player	# we at the players position so we need to skip
	lw $t1, board($t0) 		# get value in board
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
# t2 is new address
# need to not move ones we already moved
	#check if address has already been moved
	add $a0, $t0, $zero
	jal address_moved		# check if this 1 was moved into this spot
	beq $v0, 1, at_player		# not at player but does what we need it to do
	add $t2, $t0, $zero		# copy t0 (address) into t2
	srl $t2, $t2, 2			# divide by 4
	addi $t2, $t2, 8		# add by 8 cause we are zero indexed
	add $t3, $t2, $zero		# t3 is t2 before being multiplied by 4
	sll $t2, $t2, 2			# multiply by 4 for memory address
	#check for collision
	beq $t2, $s0, collison	 # collison
	# need to check bound if going off board
	add $a0, $zero, $t2
	li $a1, 252			#  is last row where sprites can move down
	jal gt
	beq $v0, 0, not_on_board 	# new address is off the board
	li $t9, 1
	sw $t9, board($t2)		# load a 1 into new memory address
	sw $zero, board($t0)		# put a zero in old memory address
	sw $t9, board_copy($t0) 	# put a 1 into copy board
	addi $s6, $s6, 1		# add 1 to number of pieces moved
	
	# now we move character on our screen black then duke
	# call getY and then use that y to put black
	# also need a getX
	
	#putting black char
	srl $t5, $t0, 2 		# address in its board location
	add $a0, $t5, 0			# $t5 is old board location
	jal getY			# y for new address
	add $a2, $v0, $zero			# a2(Y) for call to putCharXY
	jal getX
	add $t7, $v0, $zero			# x stays the same
	add $a1, $t7, $zero			# a1 for call to putChar for black
	li $a0, 2			# a0 for charcode
	jal putChar_atXY
	
	#beq $t2, $s0, collison	 # collison
	
	#putting Duke char
	add $a0, $t3, 0			# $t3 is new board location
	addi $a2, $a2, 3		# new Y is just old y plus 3
	add $a1, $t7, $zero			# same x as before
	li $a0, 1			# a0 for charcode
	jal putChar_atXY
	
	#beq $t2, $s0, collison	 # collison
	addi $t0, $t0, 4		
	j move_char
not_on_board:
	# t1 is old mem address
	lw $zero, board($t0)		# put a zero in old memory address
	# put black box on screen
	srl $t5, $t0, 2 		# address in its board location
	add $a0, $t5, 0			# $t5 is old board location
	# y for old addrees will be 24 since we are off board
	li $a2, 24			# a2(Y) for call to putCharXY
	jal getX
	add $a1, $v0, $zero			# a1 for call to putChar for black
	li $a0, 2			# a0 for charcode
	jal putChar_atXY
	addi $t0, $t0, 4		
	j move_char
	
move_player:
	# get accel value of y (left to right)
	jal get_accelY
	add $s1, $v0, $zero		# put y accel into s1
	# based on accel decide how to move
	# need a buffer so we are not moving all the time
	# butch of comparisons
	# 120 = 0x0078
	# 210 = 0x00D2
	# 300 = 0x012C
	# 390 = 0x186
	# do checking here
	add $a0, $s1, $zero
	jal no_move
	# we're back so move is happening
	# 150 - 200
	li $a0, 150
	slt $t0, $s1, $t0		# accelY < 150
	beq $t0, 1, move_right_2
	
	# not less then 150 so check if less then 200
	li $a0, 200
	slt $t0, $s1, $t0		# accelY < 200
	beq $t0, 1, move_right_1
	
	# if here we are greater then 270
	li $a0, 390
	slt $t0, $s1, $t0		# accelY < 390
	beq $t0, 1, move_left_1
	
	# if here we are greater then 270 so we are moving by 2 to the left
	beq $t0, $zero, move_left_2
	
	# if here we
move_right_1:
	#add $a0, $s1, $zero
	#li $a1, 0x00F0
	#jal no_move
	# we're back so move is happening
	# 150 - 200
	#li $a0, 150
	#slt $t0, $s1, $t0		# accelY < 150
	#beq $t0, $zero, move_right2
	#li $a1, 0x0078
	#jal gt
	#beq $v0, 0, move_right_2
	#bgt $s1, 0x0078, move_right_2
	# steps to move by 1
	#set players X to 0 in board
	add $t0, $zero, $s0		# players pos into t0
	sw $zero, board($t0)		# pos now 0
	add $s0, $s0, 4			# adding 4 to board pos (1 board space)
	# need to check if we are at edge of screen? new proc? if so set to 252
	jal boundScreen
	# move sprite	
	addi $t0, $zero, 1
	sw $s2, board($s0)		# adding 1 in new part of board 
	# putting black square
	li $a0, 2			# 2 is our charcode for black square
	add $a1, $s3, $zero			# x coord
	add $a2, $s4, $zero			# y coord
	jal putChar_atXY
	# getting new screen coords
	# need to check if x > 40 set to 40
	# need to check if x < 0 set to 
	addi $s3, $s3, 5			# adding 5 to our x coord
	jal boundX
	li $a0, 0			# 0 is unc logo
	add $a1, $s3, $zero			# s3 is x coord
	add $a2, $s4, $zero			# s4 is y coord
	jal putChar_atXY		# put unc logo at new address
	j add_enemies
move_right_2:
	#add $a0, $s1, $zero
	#li $a1, 0x00D2
	#jal gt
	#beq $v0, 0, move_left_1
	#bgt $s1, 0x00D2, move_left_1
	# steps for moving by 2
	#set players X to 0 in board
	add $t0, $zero, $s0		# players pos into t0
	sw $zero, board($t0)		# pos now 0
	add $s0, $s0, 8			# adding 8 to board pos move two spaces
	jal boundScreen
	# move spirtes
	addi $t0, $zero, 1
	sw $s2, board($s0)		# adding 1 in new part of board 
	# putting black square
	li $a0, 2			# 2 is our charcode for black square
	add $a1, $s3, $zero			# x coord
	add $a2, $s4, $zero			# y coord
	jal putChar_atXY
	# getting new screen coords
	# need to check if x > 40 set to 40
	# need to check if x < 0 set to 
	addi $s3, $s3, 10			# adding 10 to our x coord
	jal boundX
	li $a0, 0			# 0 is unc logo
	add $a1, $s3, $zero			# s3 is x coord
	add $a2, $s4, $zero			# s4 is y coord
	jal putChar_atXY		# put unc logo at new address
	j add_enemies
move_left_1:
	#add $a0, $s1, $zero
	#li $a1, 0x012C
	#jal gt
	#beq $v0, 0, move_left_2
	#bgt $s1, 0x12C, move_left_2
	#set players X to 0 in board
	add $t0, $zero, $s0		# players pos into t0
	sw $zero, board($t0)		# pos now 0
	add $s0, $s0, -4		# adding -4 to board pos (1 left)
	jal boundScreen
	# need to check if we are at edge of screen? new proc? if so set to 252
	# move spirte now
	addi $t0, $zero, 1
	sw $s2, board($s0)		# adding 1 in new part of board 
	# putting black square
	li $a0, 2			# 2 is our charcode for black square
	add $a1, $s3, $zero			# x coord
	add $a2, $s4, $zero			# y coord
	jal putChar_atXY
	# getting new screen coords
	# need to check if x > 40 set to 40
	# need to check if x < 0 set to 
	addi $s3, $s3, -5			# adding 5 to our x coord
	jal boundX
	li $a0, 0			# 0 is unc logo
	add $a1, $s3, $zero			# s3 is x coord
	add $a2, $s4, $zero			# s4 is y coord
	jal putChar_atXY		# put unc logo at new address
	j add_enemies
move_left_2:
	# if were here that means fast
	#steps for moving by 4
	add $t0, $zero, $s0		# players pos into t0
	sw $zero, board($t0)		# pos now 0
	add $s0, $s0, -8			# adding -8 to board pos (2 left)
	jal boundScreen
	# lets move our sprite now
	addi $t0, $zero, 1
	sw $s2, board($s0)		# adding 1 in new part of board 
	# putting black square
	li $a0, 2			# 2 is our charcode for black square
	add $a1, $s3, $zero			# x coord
	add $a2, $s4, $zero			# y coord
	jal putChar_atXY
	# getting new screen coords
	# need to check if x > 40 set to 40
	# need to check if x < 0 set to 
	addi $s3, $s3, -10			# adding -10 to our x coord
	jal boundX
	li $a0, 0			# 0 is unc logo
	add $a1, $s3, $zero			# s3 is x coord
	add $a2, $s4, $zero			# s4 is y coord
	jal putChar_atXY		# put unc logo at new address
	j add_enemies
no_move:
	li $t0, 190
	slt $v0, $a0, $t0	# accelY < 190 ?
	beq $v0, 1, move_happening
	li $t0, 270
	slt $v0, $a0, $t0	# accelY < 270 if yes no move
	beq $v0, $zero, move_happening
	j add_enemies		# no move accel value to small
move_happening:
	jr $ra
	
# need to add new enemies now or maybe find a way to tell how much time has passed?
add_enemies:
	# keep a count in a register and every so often lower it
	# 5 rounds
	addi $s5, $s5, 1		# adding 1 to our round counter
	add $t0, $zero, $zero
	li $t2, 0
	j clear_copy
add_enemies_2:
	# might just use my round 2 to and add every time s4 mod(8) = 3 and 7
	# 4 enemys r1
	li $s6, 0
	add $a0, $zero, $s5
	jal easy_mod_8
	beq $v0, 3, add_enemies_even
	beq $v0, 7, add_enemies_odd
	j game_loop		# no enemies to add
add_enemies_even:
	li $t0, 0
aee:
	beq $t0, 8, game_loop		#0, 2, 4, 6, 8 
	sll $t1, $t0, 2		#$ t0 * 4
	li $t2, 1
	sw $t2, board($t1)	# new enemy to board
	#get y
	add $a0, $t0, $zero
	jal getX
	add $a1, $v0, $zero		# x value
	li $a2, 3			# y is alwasy 3
	li $a0, 1		# Duke char
	jal putChar_atXY
	addi $t0, $t0, 2
	j aee
	
add_enemies_odd:
	li $t0, 1
aeo:
	beq $t0, 9, game_loop		#0, 2, 4, 6, 8 
	sll $t1, $t0, 2		#$ t0 * 4
	li $t2, 1
	sw $t2, board($t1)	# new enemy to board
	#get y
	add $a0, $t0, $zero
	jal getX
	add $a1, $v0, $zero		# x value
	li $a2, 3			# y is alwasy 3
	li $a0, 1		# Duke char
	jal putChar_atXY
	addi $t0, $t0, 2
	j aeo
	
no_enemies:
	j game_loop
	
collison: 
	# player has been hit
	# play a sound and end game
	# char Dead char at players pos
	add $s7, $t2, $zero
	# put black char
	li $a2, 21			# y is alwasy going to be 21
	add $a0, $t0, $zero
	srl $a0, $a0, 2
	jal getX
	add $t7, $v0, $zero			# x stays the same
	add $a1, $t7, $zero			# a1 for call to putChar for black
	li $a0, 2			# a0 for charcode
	jal putChar_atXY
	
	li $a0, 3
	add $a1, $s3, $zero
	add $a2, $s4, $zero
	jal putChar_atXY
	li $a0, 382219		# c4 i think
	jal put_sound
	li $a0,5000
	jal pause
	jal sound_off
	
	j end

boundScreen:
	#check boundarys for left and right
	# x < 220 for left
	# x > 252 for right
	# need stack?
	addi $sp, $sp, -8
   	sw $ra, 4($sp) 	# Save $ra
   	sw $fp, 0($sp) 	# Save $fp
   	addi $fp, $sp, 4 	# Set $fp
   	
	#blt $s0, 0, setLeftAddress
	add $a0, $s0, $zero
	li $a1, 0
	jal lt		# a0 < 0 ?
	beq $v0, 0, setLeftAddress
	
	# new code for gt
	add $a0, $zero, $s0
	li $a1, 220
	jal gt
	beq $v0, $zero, setRightAddress
	#bgt $s0, 252, setRightAddress
	
	# we are good no need to do anything
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 		# Return
setLeftAddress:
	# went past our bondadry on the left
	li $s0, 0
	
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 		# Return
setRightAddress:
	# went past our bondadry on the right
	li $s0, 252
	
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 		# Return
	
boundX:
	#check boundarys for left and right
	# x < 0 for left
	# x > 40 for right
	#stack
    	addi $sp, $sp, -8
    	sw $ra, 4($sp) 	# Save $ra
    	sw $fp, 0($sp) 	# Save $fp
    	addi $fp, $sp, 4 	# Set $fp
    	
    	addi $sp, $sp, -8 	# room for $s2-$s3
	sw $a0, 4($sp) 	# Save $a0
    	sw $a1, 0($sp) 	# Save $a1


   	
   	# need to make lt
	#blt $s3, 0, setLeftX
	add $a0, $s3, $zero
	li $a1, 0
	slt $v0, $a0, $a1		# s3 < 0 ?
	beq $v0, 1, setLeftX
	
	#gt
	add $a0, $zero, $s3
	li $a1, 40
	jal gt
	beq $v0, 0, setRightX
	#bgt $s3, 40 setRightX
	
	lw $a0, -8($fp) 	# restore $s2
	lw $a1, -12($fp) 	# restore $s3

	addi $sp, $fp, 4 	# Restore $sp
	lw $ra, 0($fp) 	# Restore $ra
	lw $fp, -4($fp) 	# Restore $fp
	jr $ra 		# Return

setLeftX:
	# went past our bondadry on the left
	li $s3, 0
	
	lw $a0, -8($fp) 	# restore $s2
	lw $a1, -12($fp) 	# restore $s3

	addi $sp, $fp, 4 	# Restore $sp
	lw $ra, 0($fp) 	# Restore $ra
	lw $fp, -4($fp) 	# Restore $fp
	jr $ra 		# Return
	
setRightX:
	# went past our bondadry on the right
	li $s3, 35
	
	lw $a0, -8($fp) 	# restore $s2
	lw $a1, -12($fp) 	# restore $s3

	addi $sp, $fp, 4 	# Restore $sp
	lw $ra, 0($fp) 	# Restore $ra
	lw $fp, -4($fp) 	# Restore $fp
	jr $ra 		# Return
    	
getY:
	# proc to get Y address of a specfic enemy
	# y <= 7, srow = 3
	addi $sp, $sp, -8
   	sw $ra, 4($sp) 	# Save $ra
   	sw $fp, 0($sp) 	# Save $fp
   	addi $fp, $sp, 4 	# Set $fp
   	
	li $t9, 7
	jal check_if_equal
	
	# need to just set v0 to number
	beq $v0, 7, set7
	beq $v0, 15, set15
	beq $v0, 23, set23
	beq $v0, 31, set31
	beq $v0, 39, set39
	beq $v0, 47, set47
	beq $v0, 55, set55
	beq $v0, 63, set63
	j row3			# none of them match so we go there
	
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 		# Return
row3: 
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	
 	addi $sp, $sp, -8
   	sw $ra, 4($sp) 	# Save $ra
   	sw $fp, 0($sp) 	# Save $fp
   	addi $fp, $sp, 4 	# Set $fp


	li $a1, 7
	jal gt
	beq $v0, 0, row6
	li $v0, 3
	
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 		# Return

row6:
	# to clear from previous call
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
# y <= 15, srow = 6
    	addi $sp, $sp, -8
   	sw $ra, 4($sp) 	# Save $ra
   	sw $fp, 0($sp) 	# Save $fp
   	addi $fp, $sp, 4 	# Set $fp
   	
	li $a1, 15
	jal gt
	beq $v0, 0, row9
	li $v0, 6
	
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 		# Return
row9:
	# to clear from previous call
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
# y <= 23, srow = 9
 	addi $sp, $sp, -8
   	sw $ra, 4($sp) 	# Save $ra
   	sw $fp, 0($sp) 	# Save $fp
   	addi $fp, $sp, 4 	# Set $fp
   	
	li $a1, 23
	jal gt
	beq $v0, 0, row12
	li $v0, 9
	
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 		# Return
row12:
	# to clear from previous call
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
# y <= 31, srow = 12
 	addi $sp, $sp, -8
   	sw $ra, 4($sp) 	# Save $ra
   	sw $fp, 0($sp) 	# Save $fp
   	addi $fp, $sp, 4 	# Set $fp
   	
	li $a1, 31
	jal gt
	beq $v0, 0, row15
	li $v0, 12
	
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 		# Return
row15:
	# to clear from previous call
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
# y <= 39, srow = 15
 	addi $sp, $sp, -8
   	sw $ra, 4($sp) 	# Save $ra
   	sw $fp, 0($sp) 	# Save $fp
   	addi $fp, $sp, 4 	# Set $fp
   	
	li $a1, 39
	jal gt
	beq $v0, 0, row18
	li $v0, 15
	
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 		# Return
row18:
	# to clear from previous call
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
# y <= 47, srow = 18
 	addi $sp, $sp, -8
   	sw $ra, 4($sp) 	# Save $ra
   	sw $fp, 0($sp) 	# Save $fp
   	addi $fp, $sp, 4 	# Set $fp
   	
	li $a1, 47
	jal gt
	beq $v0, 0, row21
	li $v0, 18
	
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 		# Return
row21:
	# to clear from previous call
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
# y <= 55, srow = 21
 	addi $sp, $sp, -8
   	sw $ra, 4($sp) 	# Save $ra
   	sw $fp, 0($sp) 	# Save $fp
   	addi $fp, $sp, 4 	# Set $fp
   	
	li $a1, 55
	jal gt
	beq $v0, 0, row24
	li $v0, 21
	
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 		# Return
row24:
	# to clear from previous call
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
# y <= 63, srow = 24
 	addi $sp, $sp, -8
   	sw $ra, 4($sp) 	# Save $ra
   	sw $fp, 0($sp) 	# Save $fp
   	addi $fp, $sp, 4 	# Set $fp
   	
	li $v0, 24
	
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 		# Return
	
mod8:
	# $a0 is what we are modding
	# check if larger then 8
	#stack
	addi $sp, $sp, -8
   	sw $ra, 4($sp) 	# Save $ra
   	sw $fp, 0($sp) 	# Save $fp
   	addi $fp, $sp, 4 	# Set $fp
   	
calc_mod:
# need to change to gt 
# also need to multiply by 5
	
	#bgt $a0, 8, mod	
	li $a1, 8
	jal gt	
	beq $v0, $zero, mod
col0:
	bne $a0, 0, col1	#0
	add $v0, $a0, $0
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 		# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 			# Return
	
col1:
	bne $a0, 1, col2
	addi $a0, $a0, 4		#5
	add $v0, $a0, $0
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 		# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 			# Return
col2:
	bne $a0, 2, col3
	addi $a0, $a0, 8		#10
	add $v0, $a0, $0
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 		# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 			# Return
col3:
	bne $a0, 3, col4
	addi $a0, $a0, 12		#15
	add $v0, $a0, $0
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 		# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 			# Return
col4:
	bne $a0, 4, col5
	addi $a0, $a0, 16		#20
	add $v0, $a0, $0
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 		# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 			# Return
col5:
	bne $a0, 5, col6
	addi $a0, $a0, 20		#25
	add $v0, $a0, $0
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 		# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 			# Return
col6:
	bne $a0, 6, col7
	addi $a0, $a0, 24		#30
	add $v0, $a0, $0
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 		# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 			# Return
col7:
	addi $a0, $a0, 28		#35
	add $v0, $a0, $0
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 		# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 			# Return

mod:
	# subtract 8 from a0 until we are no longer greater then 8
	addi $a0, $a0, -8
	j calc_mod
getX:
	# just check the mod of x
	# a0 is our number to mod
	# stack
	addi $sp, $sp, -8	# gettingX
   	sw $ra, 4($sp) 	# Save $ra
   	sw $fp, 0($sp) 	# Save $fp
   	addi $fp, $sp, 4 	# Set $fp
   	
   	# problem maybe
   	#add $t9, $a0, 0
   	#srl $a0, $a0, 2
	jal mod8
	
	#add $a0, $t9, 0
	
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 		# Return
gt:
	# $a0 > $a1 ?
	# v0 = 0 when true
	# stack 
	addi	$sp, $sp, -16		# not -
	sw	$ra, 12($sp)
	sw	$t0, 8($sp)
	sw	$a0, 4($sp)
	sw	$a1, 0($sp)
	# do comparison
	# a0 - a1
	sub $t0, $a0, $a1
	srl $t0, $t0, 31
	# v0 = 1 when a0 > a1
	add $v0, $t0, $zero
	
	lw	$ra, 12($sp)
	lw	$t0, 8($sp)
	lw	$a0, 4($sp)
	lw	$a1, 0($sp)
	addi	$sp, $sp, 16
	jr	$ra
	
lt:
	# $a0 < $a1 ?
	# v0 = 0 when true
	# stack 
	addi	$sp, $sp, -16
	sw	$ra, 12($sp)
	sw	$t0, 8($sp)
	sw	$a0, 4($sp)
	sw	$a1, 0($sp)
	# do comparison
	# a1-a0 > 0 a0 is lt
	sub $t0, $a1, $a0
	srl $t0, $t0, 31
	add $v0, $t0, $zero
	
	lw	$ra, 12($sp)
	lw	$t0, 8($sp)
	lw	$a0, 4($sp)
	lw	$a1, 0($sp)
	addi	$sp, $sp, 16
	jr	$ra
	
address_moved:
	# a0 is address
	# a0 - 32 just set as a 1 so we can skip
	# need to check if a0 - 32 is a 1 or 0
	add $t8, $a0, $zero		# t8 = a0
	addi $t8, $t8, -32, 			# t8 - 32
	slt $t9, $t8, $zero		# a0 < 0 ? first row
	beq $t9, 1, first_row
	lw $v0, board_copy($t8)	# board_copy[$t8] eithre 0 or 1
	jr $ra
first_row:
	li $v0, 0		# we are in first row so we are good
	jr $ra
clear_copy:
	beq $t0, 256, add_enemies_2	# loop throught copy of board setting everything to 0	go back to levels (wherever)
	lw $t3, board_copy($t0)
	beq $t3, 1, enemy_cleared
	addi $t0, $t0, 4
	j clear_copy
enemy_cleared:
	addi $t2, $t2, 1
	sw $zero, board_copy($t0)  	# load a 0 into the board
	beq $t2, $s6, add_enemies_2	# whereever levels is
	j clear_copy
	
easy_mod_8:
	li $t9, 8
	slt $v0, $a0, $t9
	beq $v0, 0, minus_8
	add $v0, $a0, 0
	jr $ra
minus_8:
	addi $a0, $a0, -8
	j easy_mod_8
	
check_if_equal:
	# t9 will be 7
	beq $t9, 71, row3
	beq $t9, $a0, equal
	addi $t9, $t9, 8
	j check_if_equal
equal:
	add $v0, $t9, $zero
	jr $ra
	
set7:
	li $v0, 3
	
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 		# Return
set15:
	li $v0, 6
	
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 		# Return
set23:
	li $v0, 9
	
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 		# Return
set31:
	li $v0, 12
	
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 		# Return 
set39:
	li $v0, 15
	
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 		# Return   
set47:
	li $v0, 18
	
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 		# Return \
set55:
	li $v0, 21
	
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 		# Return
set63:
	li $v0, 24
	
	addi $sp, $fp, 4 	# Restore $sp
 	lw $ra, 0($fp) 	# Restore $ra
    	lw $fp, -4($fp) 	# Restore $fp
    	jr $ra 		# Return	   	    	
end:

.include "procs_board.asm"
#.include "procs_mars.asm"
	
	


