.model small
.386
.stack 256
.data
handle          dw 0
lCase           dw 0
uCase           dw 0
words           dw 1
fbuf            db 255 dup(?)
filenameStr     db 255, ?, 255 dup(?) 
msgLength       db 13, 10, "Characters inputed: $"
msgLCase        db 13, 10, "Lowercase letters: $"
msgUCase        db 13, 10, "Uppercase Letters: $"
msgWords        db 13, 10, "Words inputed: $"
newline         db 13, 10, "$"
help            db "Specify file names in command line.", 10, 13, "The program finds, lowercase, uppercase letters, words and symbols counts.", 10, 13, "$"
tempSize        dw 0081h
tempPosLeft     dw 0081h
.code

main proc

mov ax,@data
mov ds,ax

call searchHelp                         ; Jei randa tarp parametru /? => print help ir neskaitom toliau jokiu files

repeat:
call searchFile                         ; Jei daejo iki cia reiskia tarp parametru nebuvo /? ir tada ieskom files names (*.t)
                                          
foundOneFile:
    mov dx, offset filenameStr
    mov bx, dx
    mov di, [word ptr bx]
    mov di, 255
    
    pop cx                              
    pop bx
    push si
    inc bx
                                        ; pushini cx, nes loop l6 runnint vel reikes 
    push cx                             
    push bx
    jmp l5
    
foundMoreFiles:
    mov dx, offset filenameStr
    mov bx, dx
    mov di, [word ptr bx]
    mov di, 255

    pop cx                              
    pop bx
    inc bx
    push di
    push si
    xor di, di
    xor si, si
                                        ; pushini cx, nes loop l6 runnint vel reikes 
    push cx                             ;
    push bx
    
l5:                                     ; loop l6 => printina file name po viena character
    mov ah, 02h
    mov dx, es:[bx]
    int 21h 

    inc dx
    inc bx 

loop l5                                 ; printina fail name po viena character

    pop bx
    pop cx
    
    mov ah, 02h
    mov dx, 13
    int 21h 
    
    mov ah, 02h
    mov dx, 10
    int 21h                             ; newline tarp file name ir failo informacijos  
           
    push cx                             ; Pasipushinu string length, nes jo reikes, kad string gale prideti 0  
                                            
    xor dx, dx
    xor si, si
        
l6:                                     ; loop l6 => po viena raide file name'o isiraso filenameStr sukurta bufferi, kuris yra filenameStr + 2 vietoje
    mov dx, es:[bx]                     ; i dx isikeliam pirma filename character (file1.txt) = > tai pirma bus f (ascii kodu)
    
    mov word ptr[filenameStr + 2 + si], dx
     
    inc si
    inc dx
    inc bx
          
loop l6

    pop cx                              ; poppinu string length        

    mov bx, cx                          ; pasmovinu string length i bx
    dec bx                           
        
    mov word ptr [filenameStr + 2 + bx], 0  ; gale string idedu 0    
   
    mov lCase, 0                        
    mov uCase, 0
    mov words, 1                        ; pasiressetinu file parametru counterius
    
    lea dx, [filenameStr+2]             ; tas pats kas mov dx, offset fileStr + 2 (kur prasideda filename (kuris jau yra paedittintas, kad gale butu null terminator 
    mov ax, 3d00h
    int 21h

    jc Exit
    mov [handle],ax                     ; Issaugoti deskriptoriu
    mov bx,ax

    mov ah ,3fh
    mov cx, 100h
    mov dx, offset fbuf
    int 21h                             ; Skaityti faila
    jc Exit
    or ax,ax
    jz Exit                             ; EOF - failo pabaiga
    mov cx,ax
    call printBuf
    call countLength
    call countLcase
    call countUcase
    call countWords
    mov dx, tempSize
    mov dx, tempPosLeft
    
    pop si
    push si
    cmp si, 0
    jne repeat
    
    jmp NoClose
    

Exit:
    mov bx, [handle]
    or bx,bx
    jz NoClose
    mov ah, 3Eh
    int 21h                             ; Uzdaryti faila

NoClose:
    mov ah, 4ch
    int 21h 

main endp

searchFile proc
        
    xor bx, bx
    mov ch, 0
    cmp tempSize, 0081h
    jne here
    mov cl, es:[0080h]
    jmp overHere
here:
    mov cx, tempPosLeft

overHere:    
    cmp cx, 0
    je NoClose
    mov bx, tempSize

    push bx
    push cx

findFiles:
    mov dx, es:[bx]
    cmp dx, 't.'
    je tarpoLoop
    
    inc bx
    
loop findFiles

    jmp NoClose
       
tarpoLoop:
    cmp byte ptr es:[bx], 32                     ; ASCII 32 = space
    je tarpasFound
    inc bx
loop tarpoLoop
    
    xor si, si
    jmp foundOneFile                    ; Jei ateina iki cia => reiskiasi tik vienas parametras, kuris yra filename (*.txt)

tarpasFound:
    mov tempPosLeft, cx
    mov tempSize, bx
    mov si, cx                          ; pasimovini i si kiek liko loop'o
    mov di, bx                          ; pasimovini i di nuo kurios vietos reikes pradet loop'a veliau
    pop cx                              ; issipoppini skaiciu kiek buvo is vis simboliu
    sub cx, si                          ; atemi kiek buvo is viso is kelintoj vietoj sustojo loop => gauni kurioje vietoje sustojo loop
    push cx                             ; ta skaiciu pasipushini
    jmp foundMoreFiles
       
           
searchFile endp

printBuf proc

    push ax                             ; Issaugome steke registrus, lurie keisi
    push bx
    push dx

    mov ah, 40h
    mov bx, 1
    int 21h                             ; int 21,40 - isvedimas i faila ar irengini

    pop dx                              ; Atstatome issaugotus registrus
    pop bx
    pop ax
    ret

printBuf endp

countLength proc

    push cx                 ; Issaugome steke registrus, kurie keisis
    push dx
    push ax

    mov cx, ax

    mov ah, 9
    mov dx, offset msgLength
    int 21h

    cmp cx, 9
    ja  callPrint

    mov dx, cx
    add dx, 48
    mov ah, 02h
    int 21h
    jmp exitCountParam

callPrint:
    mov ax, cx
    call print

exitCountParam:
    pop ax                  ; Atstatome issaugotus registrus
    pop dx
    pop cx
    ret

countLength endp

countLcase proc

    push cx                 ; Issaugome steke registrus, kurie keisis
    push dx
    push ax
    push bx

    mov cx, ax

    mov ah, 9
    mov dx, offset msgLCase
    int 21h

    xor bx, bx

l2:
    mov al, [fbuf+bx]
    cmp al, 'a'
    jb skip
    cmp al, 'z'
    ja skip

    inc lCase

skip:
    inc bx
    loop l2

    mov ax, lCase
    call print

    pop bx
    pop ax                  ; Atstatome issaugotus registrus
    pop dx
    pop cx
    ret

countLcase endp

countUcase proc

    push cx                 ; Issaugome steke registrus, kurie keisis
    push dx
    push ax
    push bx

    mov cx, ax

    mov ah, 9
    mov dx, offset msgUCase
    int 21h

    xor bx, bx

l3:
    mov al, [fbuf+bx]
    cmp al, 'A'
    jb skip2
    cmp al, 'Z'
    ja skip2

    inc uCase

skip2:
    inc bx
    loop l3

    mov ax, uCase
    call print

    pop bx
    pop ax                  ; Atstatome issaugotus registrus
    pop dx
    pop cx
    ret

countUcase endp

countWords proc

    push cx                 ; Issaugome steke registrus, kurie keisis
    push dx
    push ax
    push bx

    mov cx, ax

    mov ah, 9
    mov dx, offset msgWords
    int 21h

    xor bx, bx

l4:
    mov al, [fbuf+bx]
    cmp al, 32
    jne skip3

    mov al, [fbuf+bx+1]
    cmp al, 32
    je skip3

    inc words

skip3:
    inc bx
    loop l4

    mov ax, words
    call print
    
    mov ah, 9h
    mov dx, offset newline
    int 21h                             ; pirmas newline
    
    mov ah, 9h
    mov dx, offset newline
    int 21h                             ; antras newline
    

    pop bx
    pop ax                              ; Atstatome issaugotus registrus
    pop dx
    pop cx
    ret

countWords endp

print proc          
     
mov cx, 0                               ; kiek kartu padalinom, kad poto zinot kiek kartu print loop runnint, is pradziu 0
mov dx, 0 

division:                               ; division vyksta kol skaicius ax registre tampa 0
    cmp ax, 0                           ; tikrinam ar ax 0
    je print1                           ; jei lygu printinam     
                                        ; ax sedi musu skaicius
    mov bx, 10                          ; jei nelygu tai i bx registra keliam 10 (ax dalinsim is bx = skaicius / 10)       
    div bx                              ; i dx nueina liekana o ax dalmuo: pvz 32 / 10 => ax = 3, dx = 2              
         
    push dx                             ; dx pushinam i top of the stack             
        
    inc cx                              ; increasinam cx, reiskia viena kart padalinom, kitu loop vel tikrins ir t.t. (vienzenklis skaicius cx = 1, dvizenklis cx = 2 ir t.t.)              
        
    xor dx, dx                          ; nusinulinam dx, kad kitam iteration galetumem vel storint liekana
    jmp division

print1:  
    cmp cx, 0                           ; jei cx = 0, reiskia arba skaicius buvo 0 arba jau viska atprintinom                                                      
    je exitPrint                        ; kai cx 0 sokam lauk is print funkcijos
         
    pop dx                              ; poppinam virsutini elementa (jei skaicius buvo 394, tai stacke is eiles yra 3 9 4) per pirma iteration poppinam 3, tada antra 9, trecia 4

    add dx, 48                          ; kad gautumem skaiciu (ascii value)        
    mov ah, 02h                        
    int 21h                             ; isprintinam ta value
         
    dec cx                              ; decreasinam cx => toliau kita iteracija
    jmp print1                          ; kartojam print kol cx bus 0

exitPrint:
ret

print endp

searchHelp proc
    
    mov ch, 0
    mov cl, es:[0080h]
    cmp cx, 0
    je notFoundHelp
    mov bx, 0081h

findHelp:
    mov dx, es:[bx]
    cmp dx, '?/'

    je foundHelp
    inc bx
    loop findHelp

    jmp notFoundHelp

foundHelp:
    mov ah, 9
    mov dx, offset help
    int 21h
    jmp NoClose

notFoundHelp:
    ret
       
searchHelp endp

end main