; This is the boot sector code

; --------------------------------------------------------------------------------------------------------------------
; Start matter
; --------------------------------------------------------------------------------------------------------------------
[BITS 16]			; Tells the compiler to make this into 16-bit code generation
[ORG 0x7C00]			; Tells the compiler where the code is going to be
                ; in memory after it has been loaded. (HEX number)

start:

	mov [bootdrv], dl       	; Before anything else, take note of the 'drive number' where we booted from
                    ; DL tells us what 'drive number' we booted from, we need this later
                    ; Store the 'drive number' to the variable 'bootdrv'

    ; Setup the stack to be used in function calls.
    ; We can't allow interrupts while we set it up

    cli                     ; Disable interrupts (CLear Interrupts bit)
    mov ax, 0x9000          ; Put stack at 9000:0000
    mov ss, ax              ;
    mov sp, 0               ;
    sti                     ; Enable interrupts (SeT Interrupts bit)

; --------------------------------------------------------------------------------------------------------------------
; This is the main loop for the boot loader. It will wait for the "boot" command to be
; entered before the kernel is read from second sector
; see 'routines.asm' for the functions or procedures
; --------------------------------------------------------------------------------------------------------------------
mainloop:
                ; Display the "grub>" prompt
    mov si, prompt
    call putstr

                ; Begin accepting "commands" or input
    mov di, buffer
    call getstr

                ; If no command is entered show the prompt again
    mov si, buffer              ; Point SI to the beginning of the user input buffer
    cmp byte [si], 0            ; Check if the very first byte is a null terminator (empty input)
    je mainloop                 ; If empty, jump straight back to the top of mainloop

                ; compare the command issued to the "boot" command
    mov si, buffer              ; Point SI to the user's inputted string
    mov di, cmd_boot            ; Point DI to the target "boot" string
    call strcmp                 ; Run the comparison routine (sets carry flag if matched)

                ; we jump to the routine which loads the kernel when the "boot" command is issued
    jc .load_kernel             ; If carry flag is set (strings are equal), jump to .load_kernel

                ; otherwise we just show the prompt again
    jmp mainloop                ; If it didn't jump above, the command was wrong, so restart loop


    .load_kernel:
                    ; we show some message telling that the kernel is being loaded
    mov si, msg                 ; Point SI to the "Loading kernel..." message string
    call putstr                 ; Print the message to the screen

	call read_kernel        	; Load stuff from the bootdrive

	jmp dword KERNEL_SEGMENT:0	; we jump now to the memory location where the kernel was loaded

; --------------------------------------------------------------------------------------------------------------------
; Data section
; Functions and variables used by our bootstrap
; --------------------------------------------------------------------------------------------------------------------
prompt  db "haqshi@cmsc125-b3l>",0
msg     db "Loading kernel...",13,10,0
cmd_boot  db "boot",0
buffer times 64 db 0			; an empty string
bootdrv db 0                    	; The boot drive id
KERNEL_SEGMENT equ 0x1000

; --------------------------------------------------------------------------------------------------------------------
; Read few sectors from the BOOT DRIVE
; --------------------------------------------------------------------------------------------------------------------
read_kernel:
    push ds                 ; save ds
    .reset:
    mov ax, 0               ; Reset Disk first before read
    mov dl, [bootdrv]       ; Drive to reset
    int 13h                 ;
    jc .reset               ; Failed -> Try again

    pop ds

 .read:
                ; insert lines of code for reading the kernel sector
                ; you will need to use INT 0x13 (see your handouts)
                ; carefully, initialize the necessary registers (see your handouts)
    mov ax, KERNEL_SEGMENT  ; Move 0x1000 into AX (can't move directly to ES)
    mov es, ax              ; Set Extra Segment (ES) to 0x1000
    mov bx, 0               ; Set BX to 0 so ES:BX points to exactly 0x1000:0000

    mov ah, 0x02            ; Set AH to 0x02 for BIOS Read Sector service
    mov al, 1               ; Set AL to 1 to read a single sector
    mov ch, 0               ; Set CH to 0 for track/cylinder 0
    mov cl, 2               ; Set CL to 2 since the kernel is in the second sector
    mov dh, 0               ; Set DH to 0 for head 0
    mov dl, [bootdrv]       ; Set DL to the boot drive ID we saved earlier
    int 13h                 ; Trigger the BIOS interrupt to read the disk

    jc .read                ; If carry flag is set (read failed), jump back and try reading again

  retn

; Includes "routines.asm"
    %include "routines.asm"

; --------------------------------------------------------------------------------------------------------------------
; End matter
; --------------------------------------------------------------------------------------------------------------------
	times 510-($-$$) db 0	; Fill the rest of the sector with zero's
	dw 0xAA55		; Add the boot loader signature at the end, size is 2 bytes
