
.model small
.stack 100
.data
msg              db 13,10, "Iveskite eilute: $"
ats              db 13,10, "Atsakymas: $"
buff             db 255, ?, 255 dup(?)
elementsNotEqual dw 0
.code
MAIN proc

mov  dx, @data
mov  ds, dx 
                             ; i ds isikeliu data
mov  ah, 9
mov  dx, offset msg
int  21h                     ; print message

mov  ah, 0ah                 ; skaito iki enter
mov  dx, offset buff
int  21h
mov  ah, 9
mov  cl, [buff+1]

mov  ch, 0
mov  si, cx                  ; i si isikeliu cx indeksa (kad loop nuo galo eitu)
sub  si, 1                   ; -1, nes cx vienu didesnis nei paskutinio elem vieta

l:        
mov  al, ds:[buff+2+bx]         ; i al isikeliu pirma stringo elemnta
mov  ah, ds:[buff+2+si]         ; i ah isikeliu paskutini stringo elementa

cmp  al, ah                  ; comparinu, jei abu vienodi values -> pvz.: 'a' = 'a' tada je = skip ir neincrementinu elementsNotEqual, otherwise increment
je   skip

inc  elementsNotEqual

skip:     
inc  bx                      ; increasinu bx indeksa, kuris eina nuo pradziu
dec  si                      ; decreasinu si indeksa, kuriis eina nuo galo
loop l                       ; cx-- ir toliau loop kol cx != 0
	
mov  ah, 9
mov  dx, offset ats
int  21h                     ; print ats string

mov  ax, elementsNotEqual    ; ax = skaicius (pvz 13)
call PRINT

exit:     
mov  ah, 4ch
int  21h                     ; end program
MAIN endp



print proc          
     
    ;initialize count
    mov cx,0
    mov dx,0
    
    cmp ax, 0
    je PrintZero 
    ; kol skaicius tampa 0
    division:
        ; if ax is zero
        cmp ax,0
        je print1     
         
        ;initialize bx to 10
        mov bx,10       
         
        ; extract the last digit
        div bx                 
         
        ;push it in the stack
        push dx             
         
        ;increment the count
        inc cx             
         
        ;set dx to 0
        xor dx,dx
        jmp division
    print1:
        ;check if count
        ;is greater than zero
        cmp cx,0
        je exitPrint
         
        ;pop the top of stack
        pop dx
         
        ;add 48 so that it
        ;represents the ASCII
        ;value of digits
        add dx,48
         
        ;interrupt to print a
        ;character
        mov ah,02h
        int 21h
         
        ;decrease the count
        dec cx
        jmp print1

PrintZero:

mov dx, 48
mov ah, 02h
int 21h

exitPrint:

ret

print endp
end main