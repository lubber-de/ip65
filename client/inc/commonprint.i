	.zeropage
pptr:		.res 2
.bss
temp_bin: .res 1
temp_bcd: .res 2

.code
.macro print_driver_init
  ldax #cs_driver_name
  jsr print
  ldax #init_msg
	jsr print
.endmacro


.macro print_dhcp_init
  ldax #dhcp_msg
  jsr print
  ldax #init_msg
	jsr print
.endmacro

.macro print_failed
  ldax #failed_msg
	jsr print
  jsr print_cr
.endmacro

.macro print_ok
  ldax #ok_msg
	jsr print
  jsr print_cr
.endmacro


.code

.import print_a
.import print_cr
.import cs_driver_name

print_ip_config:
  ldax #ip_address_msg
  jsr print
  ldax #cfg_ip
  jsr print_dotted_quad
  jsr print_cr

  ldax #netmask_msg
  jsr print
  ldax #cfg_netmask
  jsr print_dotted_quad
  jsr print_cr

  ldax #gateway_msg
  jsr print
  ldax #cfg_gateway
  jsr print_dotted_quad
  jsr print_cr

  ldax #dns_server_msg
  jsr print
  ldax #cfg_dns
  jsr print_dotted_quad
  jsr print_cr

  ldax #dhcp_server_msg
  jsr print
  ldax #dhcp_server
  jsr print_dotted_quad
  jsr print_cr

  ldax #tftp_server_msg
  jsr print
  ldax #cfg_tftp_server
  jsr print_dotted_quad
  jsr print_cr

  rts
  
print:
	sta pptr
	stx pptr + 1
	
@print_loop:
  ldy #0
  lda (pptr),y
	beq @done_print
	jsr print_a
	inc pptr
	bne @print_loop
  inc pptr+1
  bne @print_loop ;if we ever get to $ffff, we've probably gone far enough ;-)
@done_print:
  rts


;print the 4 bytes pointed at by AX as dotted decimals
print_dotted_quad:
  sta pptr
	stx pptr + 1
  ldy #0
  lda (pptr),y
  jsr print_decimal 
  lda #'.'
  jsr print_a

  ldy #1
  lda (pptr),y
  jsr print_decimal 
  lda #'.'
  jsr print_a

  ldy #2
  lda (pptr),y
  jsr print_decimal 
  lda #'.'
  jsr print_a

  ldy #3
  lda (pptr),y
  jsr print_decimal
  
  rts

print_decimal:  ;print byte in A as a decimal number
  pha
  sta temp_bin   ;save 
  sed       ; Switch to decimal mode
  lda #0		; Ensure the result is clear
  sta temp_bcd
  sta temp_bcd+1
  ldx #8  ; The number of source bits		
  :
  asl temp_bin+0		; Shift out one bit
	lda temp_bcd+0	; And add into result
  adc temp_bcd+0
  sta temp_bcd+0
  lda temp_bcd+1	; propagating any carry
  adc temp_bcd+1
  sta temp_bcd+1
  dex		; And repeat for next bit
	bne :-
  
  cld   ;back to binary
      
  pla       ;get back the original passed in number
  bmi @print_hundreds ; if N is set, the number is >=128 so print all 3 digits
  cmp #10
  bmi @print_units
  cmp #100
  bmi @print_tens
@print_hundreds:
  lda temp_bcd+1   ;get the most significant digit
  and #$0f
  clc
  adc #'0'
  jsr print_a

@print_tens:
  lda temp_bcd
  lsr
  lsr
  lsr
  lsr
  clc
  adc #'0'
  jsr print_a
@print_units:
  lda temp_bcd
  and #$0f
  clc
  adc #'0'
  jsr print_a
  
  rts


print_hex:
  pha  
  pha  
  lsr
  lsr
  lsr
  lsr
  tax
  lda hexdigits,x
  jsr print_a
  pla
  and #$0F
  tax
  lda hexdigits,x
  jsr print_a
  pla
  rts

.rodata
hexdigits:
.byte "0123456789ABCDEF"

ip_address_msg:
	.byte "IP ADDRESS: ", 0

netmask_msg:
	.byte "NETMASK:    ", 0

gateway_msg:
  .byte "GATEWAY:    ", 0
  
dns_server_msg:
  .byte "DNS SERVER: ", 0

dhcp_server_msg:
  .byte "DHCP SERVER:", 0

tftp_server_msg:
  .byte "TFTP SERVER: ", 0

dhcp_msg:
  .byte "DHCP",0

init_msg:
  .byte " INIT ",0

failed_msg:
	.byte "FAILED", 0

ok_msg:
	.byte "OK", 0
 
dns_lookup_failed_msg:
 .byte "DNS LOOKUP FAILED", 0