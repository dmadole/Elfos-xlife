
;  Copyright 2022, David S. Madole <david@madole.net>
;
;  This program is free software: you can redistribute it and/or modify
;  it under the terms of the GNU General Public License as published by
;  the Free Software Foundation, either version 3 of the License, or
;  (at your option) any later version.
;
;  This program is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with this program.  If not, see <https://www.gnu.org/licenses/>.


           ; Include kernal API entry points

include    include/bios.inc
include    include/kernel.inc


           ; VDP port assignments

#define    VDPREG 5
#define    VDPRAM 1

#define    RDRAM 00h
#define    WRRAM 40h
#define    WRREG 80h


           ; table constants and locations

rows:      equ 48                      ; dimensions of the play field, these
cols:      equ 64                      ; match the 9918 multicolor mode

patterns:  equ 0000h                   ; locations of the display tables in
names:     equ 1000h                   ; the 9918 memory map
sprites:   equ 1300h


           ; Executable program header

           org     2000h - 6
           dw      start
           dw      end-start
           dw      start

start:     org     2000h
           br      main


           ; Build information

           db      2+80h              ; month
           db      27                 ; day
           dw      2022               ; year
           dw      2                  ; build

           db      'See github.com/dmadole/Elfos-xlife for more info',0


           ; Initialize 9918 registers to multicolor mode. We blank the display
           ; here as the first thing so initial configuration is ; hidden. The
           ; display will be re-enabled after the first generation is set into
           ; the 9918 memory so it displays all at once.

main:      sex     r3

           out     VDPREG
           db      088h                ; 16k=1, blank=0, m1=0, m2=1
           out     VDPREG
           db      WRREG + 1

           out     VDPREG
           db      0h                  ; m3=0, external=0
           out     VDPREG
           db      WRREG + 0

           out     VDPREG
           db      names >> 10         ; name table address
           out     VDPREG
           db      WRREG + 2

           out     VDPREG
           db      sprites >> 7        ; sprite attribute address
           out     VDPREG
           db      WRREG + 5

           out     VDPREG 
           db      0                   ; background color
           out     VDPREG
           db      WRREG + 7


           ; pattern table address

           ldi     low patterns
           plo     rd
           ldi     high patterns
           phi     rd


           ; write empty sprite table

           out     VDPREG
           db      low sprites
           out     VDPREG
           db      WRRAM + high sprites

           out     VDPRAM
           db      208


           ; write name table

           ldi     0
           str     r2

           out     VDPREG
           db      low names
           out     VDPREG
           db      WRRAM + high names

           sex     r2

namecol:   ldi     4
           plo     re

namerow:   out     VDPRAM
           dec     r2
           ldn     r2
           adi     6
           str     r2
           smi     192
           lbnf    namerow

           str     r2

           dec     re
           glo     re
           lbnz    namerow

           ldn     r2
           adi     1
           str     r2

           smi     6
           lbnf    namecol


           ; clear working copy

           ldi     low lastlast
           plo     r7
           ldi     high lastlast
           phi     r7

           ldi     low (lastsize+255)
           plo     r8
           ldi     high (lastsize+255)
           phi     r8

           sex     r7

zero:      ldi     0
           stxd

           dec     r8
           ghi     r8
           lbnz    zero

           lbr     copypat


           ; copy kernel code to pattern

           ldi     low 1000h
           plo     r7
           ldi     high 1000h
           phi     r7

           ldi     low nextcopy
           plo     r8
           ldi     high nextcopy
           phi     r8

           ldi     low (nextsize+255)
           plo     r9
           ldi     high (nextsize+255)
           phi     r9

copy2:     lda     r7
           ani     1

           str     r8
           inc     r8

           dec     r9
           ghi     r9
           lbnz    copy2

           lbr     display


           ; copy pattern to next generation

copypat:   ldi     low p60gs
           plo     r7
           ldi     high p60gs
           phi     r7

           ldi     low nextcopy
           plo     r8
           ldi     high nextcopy
           phi     r8

           ldi     low (nextsize+255)
           plo     r9
           ldi     high (nextsize+255)
           phi     r9

           sex     r7

copy:      lda     r7
           shr
           lbnz    run

           shlc
           str     r8
           inc     r8

           dec     r9
           ghi     r9
           lbnz    copy

           lbr     display

run:       shlc
           plo     ra

fill:      ldi     0
           str     r8
           inc     r8

           dec     r9
           dec     ra
           glo     ra
           lbnz    fill

           ghi     r9
           lbnz    copy
           

           ; difference the generations and update the old
           ;
           ; process two columns in parallel to match the display

display:   sex     r2

           ghi     rd                  ; alternate pattern address
           sdi     8
           phi     rd

           ori     WRRAM
           dec     r2
           stxd

           glo     rd
           str     r2

           out     VDPREG
           out     VDPREG

           ldi     low (lastcopy+(rows+1)+1)
           plo     r7
           ldi     high (lastcopy+(rows+1)+1)
           phi     r7

           ldi     low (lastcopy+(rows+1)*2+1)
           plo     r8
           ldi     high (lastcopy+(rows+1)*2+1)
           phi     r8

           ldi     low nextcopy
           plo     r9
           ldi     high nextcopy
           phi     r9

           ldi     low (nextcopy+rows)
           plo     ra
           ldi     high (nextcopy+rows)
           phi     ra

           ldi     cols/2                ; columns
           plo     rc

displcol:  ldi     rows                  ; rows
           plo     rb

displrow:  ldn     r7
           shl
           sex     r7
           or
           sex     r9
           xor
           shl

           shl
           shl

           sex     r8
           or
           shl
           or
           sex     ra
           xor
           shl

           str     r2
           sex     r2
           out     VDPRAM
           dec     r2

           lda     r9
           str     r7
           inc     r7

           lda     ra
           str     r8
           inc     r8

           dec     rb
           glo     rb
           lbnz    displrow

           inc     r8

           glo     r8
           plo     r7
           adi     rows+1
           plo     r8

           ghi     r8
           phi     r7
           adci    0
           phi     r8

           glo     ra
           plo     r9
           adi     rows
           plo     ra

           ghi     ra
           phi     r9
           adci    0
           phi     ra

           dec     rc
           glo     rc
           lbnz    displcol


           ; switch pattern table


           ghi     rd
           shr
           shr
           shr
           dec     r2
           str     r2

           sex     r2
           out     VDPREG
           sex     r3
           out     VDPREG
           db      WRREG + 4


           ; enable display

           out     VDPREG
           db      0c8h                ; 16k=1, blank=1, m1=0, m2=1
           out     VDPREG
           db      WRREG + 1


           ; r7 = row before source
           ; r8 = cur row source
           ; r9 = next row source

           ; ra = cur row destinaton

           ; rb = column count
           ; rc = row count

generate:  ldi     low (lastcopy+1)
           plo     r7
           ldi     high (lastcopy+1)
           phi     r7

           ldi     low (lastcopy+(rows+1)+1)
           plo     r8
           ldi     high (lastcopy+(rows+1)+1)
           phi     r8

           ldi     low (lastcopy+(rows+1)*2+1)
           plo     r9
           ldi     high (lastcopy+(rows+1)*2+1)
           phi     r9

           ldi     low nextcopy
           plo     ra
           ldi     high nextcopy
           phi     ra

           ; calculate the neighbor counts into the destination

           ldi     cols                ; columns
           plo     rc

countcol:  ldi     rows                ; rows
           plo     rb

countrow:  sex     r7

           dec     r7
           ldx
           inc     r7
           add
           inc     r7
           add

           sex     r8

           dec     r8
           add
           inc     r8
           inc     r8
           add

           sex     r9

           dec     r9
           add
           inc     r9
           add
           inc     r9
           add

           smi     3
           lbz     live

           adi     1
           lbz     keep

           ldi     0
           lskp

live:      ldi     1
           str     ra

keep:      inc     ra

           dec     rb
           glo     rb
           lbnz    countrow

           inc     r7
           inc     r8
           inc     r9

           dec     rc
           glo     rc
           lbnz    countcol

           b4      exit
           lbr     display

exit:      sex     r3

           out     VDPREG
           db      088h                ; 16k=1, blank=0, m1=0, m2=1
           out     VDPREG
           db      WRREG + 1

wait:      b4      wait

           sep     r5


           ; Initial starting pattern ("P60 Glider Shuttle") in coded format.
           ; This populates the image in row, column order, and every byte
           ; needs to be included. 0 or 1 bytes are written literally, any
           ; other value is a number of sequential zeroes to write.

p60gs:     db      224,224,224
           db      21,1,47,1,46,1,0,1,46,1,47,1,47,1,47,1,46,1,0,1,46,1,47,1,26
           db      144,167,1,0,1,46,1,1,46,1,167,144
           db      25,1,47,1,46,1,0,1,46,1,47,1,47,1,47,1,46,1,0,1,46,1,47,1,22
           db      240,240,240


lastsize:  equ     (rows+1)*(cols+2)+1

lastcopy:  ds      lastsize-1
lastlast:  ds      1

nextsize:  equ     (rows*cols)

nextcopy:  ds      nextsize-1
nextlast:  ds      1

end:       ; That's all, folks!

