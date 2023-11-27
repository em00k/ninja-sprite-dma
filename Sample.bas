'!org=57344	
'!heap=768
'!nosys 
'#!copy=H:\modules\Sample.nex

' cp .\Sample.nex H:\modules\Sample.nex

' ORG 57344 - $E000
' Fixed bank located at $E000 to $ffff
' Usable memory from $e000 to $ffff minus heap size

' Variables are store at $4000

' ULA is paged out and banks 24/25 live in slots 2&3
' For tilemap functions the relevants pages are put back 

' - Includes -------------------------------------------------------------------
#define NOSP 					' This tells nextbuild to no set a stack pointer 
#define DEBUG  					' This will display an error when a file is not found
#define NEX 					' We want to build into Sample.NEX
#include <nextlib.bas>			' The main library 
#include <nextlib.bas>			' The main library 
#include <nextlib_ints_ctc2.bas>
#include "inc-common.bas"			' Shared between all modules 

' - Populate RAM banks for generating a NEX ------------------------------------
' These files are automatically incorporated into the final NEX and do not 
' take up memory. All modules can access these banks  
' 
' banks 24 & 25 are already assigned 
' use from bank 26 on wards 
LoadSDBank("font.nxt",			0,0,0,31)		' This is the font, default palette is used 8x8  5.93kb
LoadSDBank("LightBandit.nxb",	0,0,0,32)	' 3x3 block data  2 banks 
LoadSDBank("LightBandit.nxp",	$400,0,0,32)	' palette same bank as nxb 
LoadSDBank("LightBandit.nxt",	0,0,0,34)	' Sprite data, 49 KB  = 6 banks 
'
LoadSDBank("game.afb",			0,0,0,41) 				' load music.pt3 into bank 
LoadSDBank("ts4000.bin",		0,0,0,43) 				' load the music replayer into bank 
LoadSDBank("module4.pt3",		0,0,0,44) 				' load music.pt3 into bank 

LoadSDBank("Zombie2.nxt",		0,0,0,46)				' zombie 60160 8 banks 46-54
LoadSDBank("Zombie2.nxb",		0,0,0,56)				' 3x3 block data  2 banks 

LoadSDBank("output.dat",		0,0,0,72) 				' load sample set  
' 48kb worth of sprites 


' background tile, we will use layer 2 

LoadSDBank("darkwoods.nxp", 	0,0,0,70)				' start at bank 70 palette		512bytes	
LoadSDBank("darkwoods.nxm", 	$200,0,0,70)			' load map at 512 byte offset 	1.46kb

LoadSDBank("darkwoods.nxt", 	0,0,0,71)				' tiles							5.68kb

LoadSDBank("dogrun.nxt",		0,0,0,60)				' zombie 60160 8 banks 46-54
LoadSDBank("dogrun.nxb",		0,0,0,62)				' 3x3 block data  2 banks 

asm 
	di 							; ensure interrupts are disabled 
	nextreg		DISPLAY_CONTROL_NR_69,0
	nextreg 	TRANSPARENCY_FALLBACK_COL_NR_4A,0
	nextreg 	SPRITE_TRANSPARENCY_I_NR_4B,0
end asm 

InitInterupts(41,43,44)			' set up interrupts sfxbank, playerbank, music bank 


paper 0 : cls 

Main()							' Main call 

' Main entry

Sub Main()
	' Initialization here...
	
	' This is the only loop Module Control will use
	' Other modules are daisy chained from one another 
	asm 
		
		di 
		nextreg TURBO_CONTROL_NR_07,%00000011		; 28Mhz 
		nextreg MMU2_4000_NR_52,24					; fresh banks		
		nextreg MMU3_6000_NR_53,25					; fresh banks 
		; wipe ram 
		ld 		hl,$4000 
		ld 		de,$4001 
		ld 		hl,(0)
		ld 		bc,$7d00 
		ldir 	
	end asm 

	' Start with module 1 
	SetLoadModule(ModuleSample5,0,0)
	
	' proceeding modules will chain 
	
MainLoop:
	
	ExecModule()
	
	if VarLoadModuleParameter2 = 9 
		' ExitToBasic()
		' Goto ExitToBasic
	endif 

	GOTO MainLoop 

END sub

ExitToBasic:
	asm 
		di 
		nextreg GLOBAL_TRANSPARENCY_NR_14,0 
		nextreg DISPLAY_CONTROL_NR_69,0				; L2 off 
		nextreg MMU2_4000_NR_52,10					; replace banks	
		nextreg MMU3_6000_NR_53,11					; replace banks 
		BREAK 
		ld 		hl,(23730)
		ld		sp,hl	
		jp		56 
	end asm 
end 

' Execute module id
sub ExecModule()

	dim file as string 
	 
	common$=NStr(VarLoadModule)					' get the module to load, NStr is a non ROM version of Str(ubyte)

	file="module"+common$(2 to )+".bin"			' combine in string 

	LoadSD(file,24576,$7d00,0)					' load from SD to $6000

	asm 
		; call the routine

		ld 		(execmodule_end+1),sp 			; ensure stack is always balanced 
		call 	$6000
	execmodule_end:
		ld		sp,0000

		
	end asm 
	
end sub


sub InitInterupts(byval sfxbank as ubyte, byval plbank as ubyte, byval musicbank as ubyte)
	 
	InitSFX(sfxbank)						        ' init the SFX engine, sfx are in bank 36
	InitMusic(plbank,musicbank,0000)		        ' init the music engine 33 has the player, 34 the pt3, 0000 the offset in bank 34
	SetUpCTC()							            ' init the IM2 code 
	 
	PlaySFX(3)                                    	' Plays SFX 
	EnableMusic
	EnableSFX

end sub 

ctc_sample_table:
asm 
ctc_sample_table:

	dw $4800,0,11025 ; 0jump.pcm
	dw $4900,11025-8192,8192 ; 1pickup.pcm
	dw $4b00,9632-8192,8192 ; 3punch.pcm
end asm 

' 1.pcm+2.pcm+3.pcm+
' $2000,0,11025 ; 1.pcm
' $2000,11025,14991 ; 2.pcm
' $2200,9632,10967 ; 3.pcm
