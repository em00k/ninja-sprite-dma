' ------------------------------------------------------------------------------
' Module 3 - The running ninja 
' for zombies frames : .\gfx2next.exe -tile-size=16x16 -tile-norepeat -block-size=3x3 .\Zombie2.png -preview && copy .\Zombie2.* ..\data\
' for bandits frames : .\gfx2next.exe -tile-size=16x16 -tile-norepeat -block-size=3x3 .\LightBandit.png -preview && copy .\LightBandit.n* ..\data\
' for dog frames : gfx2next -tile-size=16x16 -tile-norepeat -block-size=4x2 .\dogrun.png -preview ; copy .\dogrun.n* ..\..\data\
' gfx2next.exe -tile-size=8x8 -tile-norepeat .\darkwoods.png -preview


' ORG 24576 - $6000
' Usable memory from $6000 to $dd00 minus Heap size 32kB yeah

'; We must specify the master file 
'!master=Sample.NEX				

';if you want to vopy the finalised bin
'#!copy=h:\Modules\Module5.bin

'; modules always start at $6000 - 24576
'!org=24576
'!heap=1024
'!module 
'!noemu
'!Opt=2

' MARK: - Init and Main 

Init()
Main()

End 		' Exit module 

#include <nextlib.bas>				' stanbdard nextlib include 
#include <nextlib_ints_ctc2.bas>
#include <keys.bas>

#include "inc-common.bas"			' Common routines used in all modules 

' This is the intialisation of the module 

dim max_frame	 		as ubyte = 3
dim start_frame			as ubyte = max_frame - 3

dim zmax_frame	 		as ubyte = 8
dim zstart_frame		as ubyte = zmax_frame - 8

dim dmax_frame	 		as ubyte = 7
dim dstart_frame		as ubyte = dmax_frame - 7

const zmax_death 		as ubyte = 26
const zstart_death 		as ubyte = zmax_death - 9

const zmaxframe_run 	as ubyte = 8
const zstart_run 		as ubyte = zmaxframe_run - 8

const maxframe_stand 	as ubyte = 3
const start_stand 		as ubyte = maxframe_stand - 3

const maxframe_run 		as ubyte = 15
const start_run 		as ubyte = maxframe_run - 7

const maxframe_down 	as ubyte = 31
const start_down 		as ubyte = maxframe_down - 7

const maxframe_sword 	as ubyte = 23
const start_sword 	as ubyte = maxframe_sword - 3

const maxframe_guard	as ubyte = 19
const start_guard 	as ubyte = maxframe_guard - 3

const maxframe_dead	as ubyte = 36
const start_dead	 	as ubyte = maxframe_dead - 4


Sub Init()
	asm 
		nextreg SPRITE_CONTROL_NR_15,%00000011			; ensure sprites are on 
	end asm 
	for s = 0 to 64
		RemoveSprite(s,0)
	next 
	asm
		nextreg	MMU0_0000_NR_50, 32 
		nextreg PALETTE_CONTROL_NR_43,%00100000
	end asm 
	PalUpload($400,0,0)
	asm 
		nextreg MMU0_0000_NR_50,$ff
		ei
	end asm 
	setup_dma($dead, 256)
	DMASprite($C000)
	StopMusic()
	DrawLevel()

end sub 

Sub Main()

	' Main module routine 

	dim t		   		as ubyte = start_frame
	dim zframe   			as ubyte = zstart_frame
	dim py, repeat		as ubyte 
	dim zpy, zrepeat	as ubyte 
	dim music			as ubyte 
	dim attrib3			as ubyte = 0
	dim attrib4			as ubyte = bigsprite bor sprY2 ' bor sprX2 
	dim frame_time		as ubyte = 2 
	dim frame_time2		as ubyte = 2 
	dim frame_time3		as ubyte = 2 
	dim trig			as ubyte = 0
	dim k 				as uinteger
	dim stepsize, px,zx	as uinteger
	dim flipf			as ubyte 
	dim zdying,zhit		as ubyte 
	dim hitoff			as ubyte 
	dim l2xscroll       as uinteger 
	dim sword_delay     as ubyte = 2
	dim base_y        	as ubyte = 112
	dim damage        	as ubyte = 1
	dim zmove			as ubyte = 0 
	dim attack          as ubyte = 0 
	dim max_zombie      as ubyte = 4
	dim cur_zombie      as ubyte = 0
	dim zombie_array    as uinteger
	dim base_frame      as ubyte         
	dim keydown         as ubyte 
	dim zstep           as ubyte 
	dim spawn           as uinteger 
	dim dy, dt, dtrig   as ubyte 
	dim dx              as uinteger = 160
	dim drepeat, ddamage as ubyte 
	dim dattack         as ubyte 


	zrepeat				= 1 			' repeate zombie timer 
	drepeat				= 1 			' repeate zombie timer 
	stepsize			= 3
	trig 				= 10 
	zx					= 320
	zhit                = 4 
	zmove				= 0 
	'CLS256(0)

	'L2Text(0,0,"This is Module 2",FONT1,0)					' show some infos 
	'L2Text(0,1,"Keys 1/2 swap X2",FONT1,0)					' show some infos 
	'L2Text(0,2,"Keys Q/A/O/P/D/SP",FONT1,0)					' show some infos 
	
	big_sprite()
	ClipLayer2(0,255,0,255)
	ScrollLayer(0,-8)
	attrib3 = sprXmirror
	DisableMusic
	AddZombie(0)

	spawn = 500

	Do 
		asm 
		 ;   nextreg TRANSPARENCY_FALLBACK_COL_NR_4A,255
		end asm 

		spawn = spawn - 1

		if l2xscroll > 320 : l2xscroll = 0 : endif 
		ScrollL2Word(l2xscroll)
		
		k = GetKeyScanCode()

		kemp = in 31 
		if kemp BAND 1
			k = KEYP
		elseif kemp BAND 2
			k = KEYO 
		elseif kemp BAND 8
			k = KEYQ	
		endif 
		if kemp BAND 16 
			k = 16 
		endif 

		zstep   = 0 

		if k = KEYP			
			
			attrib3 = sprXmirror				'  %1000 = left 
			if 		trig = 0 or trig = 3 : trig 	= 1 : endif 
			if hitoff = 0
				if  px > 160
					l2xscroll   = l2xscroll + stepsize
					zstep       = stepsize
				else

					px 		= px + stepsize 

				endif  
			endif 
			damage = 1 
			
		elseif k 	= KEYO
			attrib3 = 0
			if 		trig = 0 or trig = 3: trig 	= 1 : endif 
			if px   < 24
				'
			else 
				px      = px - stepsize 
			endif 
			damage = 1

		elseif k 	= KEYA 
			if 		trig = 0 : trig 	= 4 : endif 
		elseif k 	= KEYQ
			if 		trig = 0 : trig 	= 5 : endif 

		elseif k 	= KEYD
			if 		trig = 0 : trig 	= 6 : endif 
			
		elseif k 	= KEY1
			attrib4	= bigsprite bor sprY2
			stepsize= 3
			base_y  = 112
		elseif k 	= KEY2
			attrib4	= bigsprite
			stepsize= 2
			base_y  = 160
		elseif k 	= KEYM
			music = 1 - music 
			if music = 1 
				EnableMusic
			else 
				DisableMusic
			endif 

		elseif k 	= KEYZ and keydown = 0 


			keydown = 1 

		elseif k 	= 0 and trig > 0 
			trig 	= 10
			zstep   = 0 
		elseif GetKeyScanCode()=0 
			keydown = 0 
		endif 

		if spawn    = 0
			for p = 0 to 4 
				zombie_array = @zombie_data+(cast(uinteger,p)*13)
				if peek(zombie_array) = 0

					AddZombie(p)
					p = 4 
				endif 
			next 
			rand()
			spawn = peek (@rand_num)
		endif 


		if MultiKeys(KEYSPACE) or k = 16
			if 	hitoff = 0 and sword_delay = 0 
				trig 	= 3
				hitoff  = 1 
				attack = 1
				' endif 
				sword_delay = 2    
			endif 
			
		elseif  MultiKeys(KEYSPACE) = 0 
				if sword_delay 
					sword_delay = sword_delay - 1
				else 
					hitoff  = 0 
				endif 
				
		endif 
		

	''	zombie animation 
		'

	for zcount = 0 to 3                  '; loop around zombie array 
	
		zombie_array = @zombie_data+cast(uinteger,zcount)*13        ''; size of array 12

		if peek(zombie_array) = 1                                  ''; its enabled 
		
			zx          = peek(uinteger, zombie_array+1)
			'zy          = peek(zombie_array+3)
			zframe      = peek(zombie_array+4)
			zmove       = peek(zombie_array+5)
			zmax_frame  = peek(zombie_array+6)
			zstart_frame= peek(zombie_array+7)
			zhit        = peek(zombie_array+8)
			zrepeat     = peek(zombie_array+9)
			zdying      = peek(zombie_array+10)
			frame_time2 = peek(zombie_array+11)
			base_frame  = peek(zombie_array+12)

			dim dist		as uinteger = zx-px

			if 	dist 		<= 4 and zhit 
				if attrib3	= sprXmirror
					px 		= px - 8
				else 
					px 		= px + 8
				endif 
				trig  		= 7 
			endif


			if zdying = 0 
				zx = zx - zstep 
			else 
				zx = (zx - zstep  ) + 2 
			endif 

			if frame_time2 = 0 

				if attack = 1 and dist < 18
					if zhit 
						zframe 			 = 16
						zhit         = (zhit - damage ) band %110
						if damage	> 1
							zmove = 1 
						endif
						if zhit = 0 
							zmax_frame 	 = zmax_death
							zstart_frame = zstart_death
							zframe 			 = zstart_frame
							zrepeat 	 = 2
							zdying 		 = 1
							
						endif     
						attack       = 0 
						PlaySFX(9)  
					endif
				endif 


				border 2	
				MetaSprite(zframe,base_frame,56,46,9)
				border 0 
				' check if we are going to loop 
				zframe = zframe + 1  
				if zmove > 0
					zmove = zmove + 1 
					if zmove = 7 : zmove = 0 : endif 
					zx = zx + peek(@zombiemove+cast(uinteger,zmove))
				else
					zx = zx - 1
					zmove = 0 
				endif 
				
				if zframe > zmax_frame
					if zrepeat 	= 1 
						zframe 		= zstart_frame
					elseif zrepeat = 2 
						'zmax_frame 		= zmaxframe_run
						'zstart_frame 	= zstart_run
						'zframe 		= zstart_frame
						'zdying 	= 0 
						'zx 		= 320
						'zrepeat = 1
						'zhit    = 8
						poke uinteger zombie_array, 0    
					else 
						zframe = zmaxframe_run
					endif			
				endif 
				frame_time2 = 4
			else
				frame_time2 = frame_time2 - 1	
			endif

			poke uinteger zombie_array+1, zx          
			'poke zombie_array+3, zy          
			poke zombie_array+4, zframe      
			poke zombie_array+5, zmove       
			poke zombie_array+6, zmax_frame  
			poke zombie_array+7, zstart_frame
			poke zombie_array+8, zhit        
			poke zombie_array+9, zrepeat     
			poke zombie_array+10, zdying      
			poke zombie_array+11, frame_time2 

			UpdateSprite( zx , base_y-4 , base_frame, base_frame , 0 , attrib4 )            '; display zombie 

		endif 

	next zcount	

	   		' 
	' dog animation 
	'
		dim dist2		as uINTEGER 
		dist2 = zx-dx 

		if 	dist2 		<= 8 
			if attrib3	= sprXmirror
			'px 		= px - 8
			else 
		   '' px 		= px + 8
			endif 
			'trig  		= 7 
			'dx = 0
		endif

	if frame_time3 = 0 
		border 2	
		MetaSprite(dt,45+9,62,60,8)

		border 0 
		' check if we are going to loop 
		dt = dt + 1  
		if dt > dmax_frame
			if drepeat = 1 
				dt = dstart_frame
			elseif drepeat = 2
				ddamage = 1 
				dtrig = 10
			else 
				dt = dmax_frame
				dattack = 0 
			endif			
		endif 
		frame_time3 = 2
	else
		frame_time3 = frame_time3 - 1	
	endif		' 

	dx = dx + 4 
	UpdateSprite( cast(uinteger,dx) , 56+base_y+dy , 45+9, 45+9 , sprXmirror , bigsprite )




	'//MARK: - Player logic 

		' dist = 76 swiping enable 
		' dist = 68 hit range 
	if trig = 1 
		max_frame 	= maxframe_run
		start_frame = start_run
		t 			= start_frame
		trig 		= 2 
		repeat		= 1 

	elseif trig = 10 
		max_frame 	= maxframe_stand
		start_frame = start_stand
		t 			= start_frame
		trig 		= 0 
		repeat		= 1 

	elseif trig = 4
		max_frame 	= maxframe_down
		start_frame = start_down
		t 			= start_frame
		trig 		= 2 
		repeat  	= 0 
	elseif trig = 3
		max_frame 	= maxframe_sword
		start_frame = start_sword
		t 			= start_frame
		trig 		= 11 
		repeat		= 0 
		poke $fd3f,1
	elseif trig = 5
		max_frame 	= maxframe_guard
		start_frame = start_guard
		t 			= start_frame
		trig 		= 2 
		repeat		= 0
		damage      = 4
		poke        $fd3f,2
	elseif trig = 6
		max_frame 	= maxframe_dead
		start_frame = start_dead
		t 			= start_frame
		trig 		= 2 
		repeat		= 0 
		poke        $fd3f,3
	elseif trig = 7			' hit 
		max_frame 	= 35
		start_frame = 32
		t 			= 32
		trig 		= 2 
		repeat		= 2 
		poke        $fd3f,3
	endif 



		' 
		' player frame animation 
		'
		if frame_time = 0 
			border 2	
			MetaSprite(t,0,32,34,9)

			border 0 
			' check if we are going to loop 
			t = t + 1  
			if t > max_frame
				if repeat = 1 
					t = start_frame
				elseif repeat = 2
					damage = 1 
					trig = 10
				else 
					t = max_frame
					
					if trig = 11
						trig = 1
						hitoff = 0 
					endif 
				endif			
			endif 
			frame_time = 4
		else
			frame_time = frame_time - 1	
		endif		' 


		UpdateSprite( cast(uinteger,px) , base_y+py-4 , 0, 1 , attrib3 , attrib4 )

 
		'L2Text(0,3,NStr(px)+" "+NStr(zx),FONT1,255)
		'L2Text(0,4,NStr(dist),FONT1,255)
		asm 
			nextreg TRANSPARENCY_FALLBACK_COL_NR_4A,0
		end asm         
		WaitRetrace2(200)									' wait vblank

	Loop 

	VarLoadModule=ModuleSample2
	
end sub 

sub AddZombie(byval zmnum as ubyte)

	zombie_array = @zombie_data+(cast(uinteger,zmnum)*13)

	poke zombie_array, 1        ' enable 
	poke uinteger zombie_array+1, 320
	' poke zombie_array+3, zy          
	poke zombie_array+4, zstart_run      
	poke zombie_array+5, 0       
	poke zombie_array+6, zmaxframe_run  
	poke zombie_array+7, zstart_run
	poke zombie_array+8, 8         
	poke zombie_array+9, 1     
	poke zombie_array+10, 0      
	poke zombie_array+11, 0 


end sub 
zombie_data: 
asm 
	; room for 8 zombies 
	db 0            ; 1 active 
	dw 0000         ; 2  zx 
	db 0,0,0,0,0    ; 5  y, zframe, zmove, zmax_frame, zstart_frame
	db 0,1,0,0,9      ; 4  zhit, zrepeat, zdying, frame_time2
	db 0            ; 1 active 
	dw 0000         ; 2  zx 
	db 0,0,0,0,0    ; 5  y, zframe, zmove, zmax_frame, zstart_frame
	db 0,1,0,0,18      ; 4  zhit, zrepeat, zdying, frame_time2
	db 0            ; 1 active 
	dw 0000         ; 2  zx 
	db 0,0,0,0,0    ; 5  y, zframe, zmove, zmax_frame, zstart_frame
	db 0,1,0,0,27      ; 4  zhit, zrepeat, zdying, frame_time2
	db 0            ; 1 active 
	dw 0000         ; 2  zx 
	db 0,0,0,0,0    ; 5  y, zframe, zmove, zmax_frame, zstart_frame
	db 0,1,0,0,36      ; 4  zhit, zrepeat, zdying, frame_time2
	db 0            ; 1 active 
	dw 0000         ; 2  zx 
	db 0,0,0,0,0    ; 5  y, zframe, zmove, zmax_frame, zstart_frame
	db 0,1,0,0,45    ; 4  zhit, zrepeat, zdying, frame_time2

end asm 

sub MetaSprite(byval msprite as ubyte, byval basessprite as ubyte, byval blockbank as ubyte, byval sprbank as ubyte, byval blksize as ubyte)

	dim offset		as uinteger
	dim	spr_count 	as ubyte = 0
	dim	spr_id  	as ubyte = 0
	 
	'asm 
	''		nextreg	MMU2_4000_NR_52,32			; bring in block map
	'end asm 
	NextRegA(MMU2_4000_NR_52,blockbank)

	offset = $4000+cast(uinteger, msprite) * cast(uinteger,blksize)
	
	for sy = 0 to blksize-1		
		spr_id		= peek(ubyte, (offset+spr_count))
		AddSprite2(basessprite+spr_count, spr_id, sprbank )
		spr_count 	= spr_count + 1
	next 
	 
end sub 

sub big_sprite()
	UpdateSprite( 32 	, 32 	, 0, 1 , sprXmirror , bigsprite )   ' *x*
	UpdateSprite( -16 	, 00 	, 1, 0 , 0, relative )				' x**
	UpdateSprite( 16	, 00 	, 2, 2 , 0 ,relative )				' **x

	UpdateSprite( -16 	, 16 	, 3, 3 , 0 ,relative )
	UpdateSprite( 0 	, 16 	, 4, 4 , 0 ,relative )
	UpdateSprite( 16 	, 16 	, 5, 5 , 0 ,relative )

	UpdateSprite( -16 	, 16+16 , 6, 6 , 0 ,relative )
	UpdateSprite( 0 	, 16+16 , 7, 7 , 0 ,relative )
	UpdateSprite( 16	, 16+16 , 8, 8 , 0 ,relative )

	for zsprite = 9 to 45 step 9 
	UpdateSprite( 160 	, 64 	, zsprite, zsprite, sprXmirror , bigsprite )
	UpdateSprite( 16 	, 0 	, zsprite+1, zsprite+1 , 0 ,relative )
	UpdateSprite( 16+16 , 0 	, zsprite+2, zsprite+2, 0 ,relative )
	UpdateSprite( 0 	, 16 	, zsprite+3, zsprite+3, 0 ,relative )
	UpdateSprite( 16 	, 16 	, zsprite+4, zsprite+4, 0 ,relative )
	UpdateSprite( 16+16 , 16 	, zsprite+5, zsprite+5, 0 ,relative )
	UpdateSprite( 0 	, 16+16 , zsprite+6, zsprite+6, 0 ,relative )
	UpdateSprite( 16 	, 16+16 , zsprite+7, zsprite+7, 0 ,relative )
	UpdateSprite( 16+16 , 16+16 , zsprite+8, zsprite+8, 0 ,relative )
	RemoveSprite(zsprite,0)
	next 
	zsprite = 45+9
	UpdateSprite( 160 	, 64 	, zsprite, zsprite, sprXmirror , bigsprite )
	UpdateSprite( 16 	, 0 	, zsprite+1, zsprite+1 , 0 ,relative )
	UpdateSprite( 32    , 0 	, zsprite+2, zsprite+2, 0 ,relative )
	UpdateSprite( 48 	, 0 	, zsprite+3, zsprite+3, 0 ,relative )
	UpdateSprite( 0   	, 16 	, zsprite+4, zsprite+4, 0 ,relative )
	UpdateSprite( 16    , 16 	, zsprite+5, zsprite+5, 0 ,relative )
	UpdateSprite( 32 	, 16    , zsprite+6, zsprite+6, 0 ,relative )
	UpdateSprite( 48 	, 16    , zsprite+7, zsprite+7, 0 ,relative )
	RemoveSprite(zsprite,0)
end sub 


Sub fastcall AddSprite(byVal sprite as ubyte,byval spraddress as ubyte,bank as ubyte=$0)
	' uploads sprites from memory location to sprite memory 
	' Total = number of sprites, spraddess memory address, optinal bank parameter to page into slot 0/1 
	' works for both 8 and 4 bit sprites 

	asm  
		PROC
		LOCAL spr_address, sploop, sp_out
		

		pop 	hl 
		ex 		(sp), hl 
		ld      d, a                                                        ; save Total sprites from a to d 
		 
		ld 		l, 0 
		
		exx     
		pop     hl
		exx                                                                 ; save ret address  18 T  3bytes , 36 T with exx : push hl : exx   

		
		ld 		bc, SPRITE_STATUS_SLOT_SELECT_P_303B						; first sprite 
		out 	(c), a

		; let check if a bank was set ? 
		; h still has the sprite offset 
		
		ld 		a, h 														; get sprite offset into a
		swapnib 															; / 16
		and 	15															; we only want the bottom 4 bits
		srl 	a															; / 2 
		srl 	a															; / 2  a now / 64
		add 	a,a															; double a because of banking
		ld		d, a  														; save a into d 

		ld 		a, h 														; get back sprite offset 
		and 	63															; wrap around 63
		ld 		h, a 														
		ld      (spr_address+1), hl                                         ; save spr_address  16 T    3bytes 
		pop     af  														; get bank off stack 
		
		add 	a, d                                                        ; bank in a  er 
		nextreg $50,a                                                       ; setting slot 0 to a bank  
		inc     a 
		nextreg $51,a                                                       ; setting slot 1 to a bank + 1 

	spr_address: 
		ld      hl,0                                                        ; smc from above 

	sploop:                                                                 ; sprite upload loop 

		ld 		bc,$005b					
		otir

		nextreg $50, $FF                                                    ; restore rom 
		nextreg $51, $FF                                                    ; restore rom 

	sp_out:
		exx    
		push    hl 
		exx 
		; BREAK 
		ENDP 

	end asm 

end sub

Sub fastcall AddSprite2(byVal sprite as ubyte,byval spraddress as ubyte,bank as ubyte=$0)
	' uploads sprites from memory location to sprite memory 
	' Total = number of sprites, spraddess memory address, optinal bank parameter to page into slot 0/1 
	' works for both 8 and 4 bit sprites 

	asm  
		PROC
		LOCAL  sp_out
		

		pop 	hl 
		ex 		(sp), hl 
		ld      d, a                                                        ; save Total sprites from a to d 		 
		ld 		l, 0 
		
		exx     
		pop     hl
		exx                                                                 ; save ret address  18 T  3bytes , 36 T with exx : push hl : exx   

		
		ld 		bc, SPRITE_STATUS_SLOT_SELECT_P_303B						; first sprite 
		out 	(c), a

		; let check if a bank was set ? 
		; h still has the sprite offset 
		; 
		
		ld 		a, h 														; get sprite offset into a
		swapnib 															; / 16
		and 	15															; we only want the bottom 4 bits
		srl 	a															; / 2 
		srl 	a															; / 2  a now / 64
		add 	a,a															; double a because of banking
		ld		d, a  														; save a into d 

		pop     af  														; get bank off stack 
		
		add 	a, d                                                        ; bank in a  er 
		nextreg $50,a                                                       ; setting slot 0 to a bank  
		inc     a 
		nextreg $51,a                                                       ; setting slot 1 to a bank + 1 

		ld 		a, h 														; get back sprite offset 
		and 	63															; wrap around 63
		ld 		h, a 														

		call 	DMASprite

		nextreg $50, $FF                                                    ; restore rom 
		nextreg $51, $FF                                                    ; restore rom 

	sp_out:
		exx    
		push    hl 
		exx 
		; BREAK 
		ENDP 

	end asm 

end sub

sub fastcall setup_dma(byval dma_source_address as uinteger, byval dma_length as uinteger)
	asm 
	;BREAK 
	;------------------------------------------------------------------------------
	; hl = source
	; bc = length
	;------------------------------------------------------------------------------
	TransferDMASprite:

		ld 		(DMASourceS),hl
		pop 	hl 
		ex 		(sp), hl 

		exx 
		pop 	hl 
		exx

		ld 		(DMALengthS),hl
		
		
		ld 		hl,DMACodeS
		ld 		b,DMACode_LenS
		ld 		c,Z80_DMA_PORT_DATAGEAR
		otir
		exx    
		push    hl 
		exx 
		ret

	DMACodeS:
		db 		DMA_DISABLE
		db 		%01111101                   	; R0-Transfer mode, A -> B, write adress 
												; + block length
	DMASourceS:
		dw 		0                        		; R0-Port A, Start address (source address)
	DMALengthS:
		dw 		$100                        		; R0-Block length (length in bytes)
		db 		%01010100                   	; R1-read A time byte, increment, to 
												; memory, bitmask
		db 		%00000010                   	; R1-Cycle length port A
		db 		%01101000                   	; R2-write B time byte, increment, to 
												; memory, bitmask
		db 		%00000010                   	; R2-Cycle length port B
		db 		%10101101                   	; R4-Continuous mode (use this for block
												; transfer), write dest adress
		dw 		SPRITE_PATTERN_P_5B          	; R4-Dest address (destination address)
		db 		%10000010                   	; R5-Restart on end of block, RDY active
												; LOW
		db 		DMA_LOAD                    	; R6-Load
		db 		DMA_ENABLE                  	; R6-Enable DMA
		DMACode_LenS		                   equ $-DMACodeS

	end asm 
end sub 

SUB fastcall DMASprite(byval dma_source_address as uinteger)
'
asm 	

DMASprite: 
	; sprite select port should already be set 
	; hl address of sprite data 
	ld 		bc,(%0001_1101<<8)|Z80_DMA_PORT_DATAGEAR			; 7 R0-Transfer mode, A -> B, write adress ; 7 DMAPORT									
	out 	(c),b							; 12 
	out 	(c),l							; 12 start address in hl 
	out 	(c),h							; 12 
	ld 		hl,(DMA_ENABLE<<8)|DMA_LOAD		; 17
	out 	(c),l 							; 12 
	out		(c),h 							; 12 
	ret 									; 10 		87 T 

end asm 	
end sub 

zombiemove:
asm 
			db 1,3,4,5,6,6,5,4,3,1 
end asm 

sub rand() 

	asm 
	rnd:
		ld      hl,0xA280   ; yw -> zt
		ld      de,0xC0DE   ; xz -> yw
		ld      (rnd+4),hl  ; x = y, z = w
		ld      a,l         ; w = w ^ ( w << 3 )
		add     a,a
		add     a,a
		add     a,a
		xor     l
		ld      l,a
		ld      a,d         ; t = x ^ (x << 1)
		add     a,a
		xor     d
		ld      h,a
		rra             ; t = t ^ (t >> 1) ^ w
		xor     h
		xor     l
		ld      h,e         ; y = z
		ld      l,a         ; w = t
		ld      (rnd+1),hl
		ld      (rand_num), a
	end asm 

end sub 

rand_num:
	asm 
	rand_num:
		dw 00
	end asm 

sub fastcall ScrollL2Word(byval layer2_offset as uinteger)
	asm 

		; hl is amount        
		ld 		a, h                        ; 4 
		nextreg	LAYER2_XOFFSET_MSB_NR_71,a  ; 17
		ld 		a, l                        ; 4 
		nextreg LAYER2_XOFFSET_NR_16, a     ; 17 
		ret 
	end asm 
end sub 

sub DrawLevel()             '//MARK: - DrawLevel()

	dim tile_offset          as uinteger = 0 
	dim tile                 as ubyte    = 0 
	' bring in map bank 
	
	asm 
		nextreg LAYER2_RAM_BANK_NR_12, 80>>1        ; set L2 RAM at bank 80 
		nextreg ULA_CONTROL_NR_68, 1<<7             ; ULA off 
		nextreg MMU1_2000_NR_51, 70                 ; palette $0 and map $200 bank 
		nextreg LAYER2_CONTROL_NR_70, %00_01_0000   ; enable 320x256
		nextreg PALETTE_CONTROL_NR_43,%0_001_0000   ; layer 2 first palette       
	end asm 

	' Uploade palette 
	PalUpload($2000,0,0)

	' now draw 20x15 16x16 L2 tiles 

	const BASETILE  as uinteger = $2200 

	for y = 0 to 15 
		for x = 0 to 19 
		'asm 
		'nextreg MMU1_2000_NR_51, 70                 ; palette $0 and map $200 bank 
		'end asm 
		tile_offset = cast (uinteger, x) + (cast(uinteger,y) * 25)
		tile = peek(ubyte, BASETILE + tile_offset)
		' FL2Text(0,0,NStr(tile),FONT1)
		FDoTile16( tile ,x,y,71)  

		next x 
	next y 

	asm 
		nextreg MMU1_2000_NR_51, $ff
	end asm 

end sub 