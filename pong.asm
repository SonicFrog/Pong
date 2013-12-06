; Pong

.equ BALL, 0x1000
.equ PADDLES, 0x1010
.equ SCORES, 0x1018				; Quartier populaire : https://www.youtube.com/watch?v=UkBEqXbtPcQ

.equ LEDS, 0x2000
.equ BUTTONS, 0x2030

addi sp, sp, 0x1800				; On initialise le stack pointer

call init_game

main:

call move_paddle				; On déplace les paddles

call draw_paddle				; On dessine les paddles

call hit_test                   ; On appele hit_test

call move_ball                  ; On déplace la balle

ldw t0, BALL(zero)              ; On charge la position de la balle
ldw t1, BALL+4(zero)            ; On charge la position y

addi a0, t0, 0                  ; On met x dans a0
addi a1, t1, 0                  ; On met y dans a1

call set_pixel                  ; On appelle set_pixel

beq v0, zero, after_score		; Si aucun gagnant on affiche pas le score

slli v0, v0, 1
ldw t0, SCORES(v0)
addi t0, t0, 1
stw t0, SCORES(v0)

call display_score				; On affiche le score

call check_winner				; On vérifie si le score max est atteint

after_score:

call wait						; On attend un peu

call clear_leds                 ; On reset l'écran

br main


display_score:
ldw t0, SCORES(zero)		; On charge les deux scores
ldw t1, SCORES+4(zero)
slli t0, t0, 2
slli t1, t1, 2
ldw t2, font_data(t0)		; Le score du joueur 1
ldw t3, font_data(t1)		; Le score du joueur 2
stw t2, LEDS(zero)
stw t3, LEDS+8(zero)		; On affiche les scores
addi t4, zero, 0xFF
slli t4, t4, 16
stw t4, LEDS+4(zero)

check_new_round:
ldw t0, BUTTONS+4(zero)		; On charge edgecapture
beq t0, zero, check_new_round
stw zero, BUTTONS+4(zero)

ret


check_winner: 				; Vérifie si un des deux joueurs a atteint 15 points
ldw t0, SCORES(zero)
ldw t1, SCORES(zero)
addi t2, zero, 0xF
beq t0, t2, is_winner
beq t1, t2, is_winner
ret

is_winner:
break

; a0 : the x coordinate
; a1 : the y coordinate
set_pixel:

addi sp, sp, -20
stw t0, 4(sp)
stw t1, 8(sp)
stw t4, 12(sp)
stw t5, 16(sp)
stw t6, 20(sp)

slli t0, a0, 3 					; On shift pour mettre la coordonnées x^3 dans t0
add t0, t0, a1					; On lui additionne la coordonnées y
srli t1, t0, 3 					; On shift pour mettre la valeur d'addressage en byte
ldw t6, 0x2000(t1)  			; On lit la valeur actuelle du byte ou on doit écrire
addi t4, zero, 32
add t5, t0, zero
loop:
blt t5, t4, end_loop			; Si l'adresse à l'intérieur des leds est inférieure à 31 c'est ok
addi t5, t5, -32 				; Sinon on lui soustrait 31
br loop

end_loop:
addi t1, zero, 1 				; On met 1 dans t1
sll t1, t1, t5 	 				; On shift de sa position en nombre de bit 
or t6, t1, t6    				; On force le bit à sa place dans la valeur lue du mot
srli t0, t0, 3
stw t6, LEDS(t0) 				; On stocke ce nouveau mot dans la mémoire

ldw t6, 20(sp)
ldw t5, 16(sp)
ldw t4, 12(sp)
ldw t1, 8(sp)
ldw t0, 4(sp)
addi sp, sp, 20

ret

hit_test:
; On vérifie d'abord sur x
addi v0, zero, 0				; On met v0 à zéro au cas ou il contient déjà quelque chose
addi s0, zero, 1			   ; La coordonnées minimale sur x pour laquelle on check le paddle
addi s1, zero, 10				; La coordonnées maxi sur x
addi t5, zero, 0				; L'offset pour la position du paddle

ldw t0, BALL(zero)             ; On charge la position x de la balle

addi t1, zero, 11              ; On met la valeur max de x dans t1
beq t0, s0, check_paddle_pos           ; Si x est 1 on check la position du paddle 1
addi t5, t5, 4					; On augmente l'offset
beq t0, s1, check_paddle_pos           ; Si x est 11 on est aussi dans un bord

br check_y

invert_x:
ldw t1, BALL + 8(zero)          ; On charge la valeur de velocité x
ori t2, zero, 0xFFFF            ; On met FFFF dans t2
slli t2, t2, 16                 ; On shift t2 de 16 vers la gauche
                                ; pour avoir FFFF000000
ori t2, t2, 0xFFFF              ; On le or avec FFFFF pour obtenir 32
                                ; bit à 1
xor t1, t1, t2                  ; On xor avec t1 pour le complément à deux
addi t1, t1, 1                  ; On ajoute 1 pour faire le complément
                                ; à deux
stw t1, BALL + 8 (zero)         ; On stocke cette valeur dans la mémoire

check_y:                        ; On vérifie sur y
ldw t0, BALL + 4(zero)          ; On charge la position y
addi t1, zero, 7                ; On met la valeur de y dans t1
beq t0, zero, invert_y          ; Si y = 0 on inverse la velocité
beq t0, t1, invert_y            ; Si y = 7 on inverse aussi
br end                          ; Sinon on fini la procédure


check_paddle_pos:
ldw t0, BALL+4(zero)			; On charge la position y de la balle
ldw t4, PADDLES(t5)				; On charge la position du paddle
blt t0, t4, paddle_miss			; Si la position de la balle est inférieure à celle du paddle
addi t4, t4, 4					; On augmente la position du paddle de 4 pour vérifier l'autre côté
bge t0, t4, paddle_miss			; Même chose on brance à paddle miss si c'est à côté
br invert_x          			; Sinon on revient pour vérifier y


paddle_miss:
addi t5, t5, 4					; On ajoute 4 dans t5 pour avoir un resultat non zéro quand on divise
srli t5, t5, 2					; On calcule le numéro du joueur qui a laissé passer le paddle
addi s6, zero, 2				; On met s6 à 2 pour comparer
beq s6, t5, p1_wins				; Si t5 est 2 c'est le premier joueur qui gagne
addi v0, zero, 2				; Sinon c'est le joueur deux
br invert_x						; Mais on doit quand même aller inverser x XD

p1_wins:
addi v0, zero, 1				; Le joueur 1 gagne
br invert_x


invert_y:
ldw t1, BALL + 0xC(zero)        ; On charge la velocité
ori t2, zero, 0xFFFF            ; On remplit t2 avec des 1 pour le
                                ; complément à 2
slli t2, t2, 16
ori t2, t2, 0xFFFF
xor t1, t1, t2
addi t1, t1, 1
stw t1, BALL + 0xC(zero)        ; On stocke la valeur inversée
br end

end:
ret                             ; Fin de hit_test


move_paddle:
ldw t0, BUTTONS+4(zero)			; On charge la valeur du edgecapture
addi t6, zero, 0				; t6 contient l'offset actuel depuis PADDLES
addi t5, zero, 8				; t5 contient l'offset maximal depuis PADDLES

mv_paddle:
addi t7 , zero, 1				; On met 1 dans t7 pour comparer ensuite
andi t1, t0, 1					; On regarde si le premier bouton a été appuyé
beq t1, t7, move_paddle_right	; Si le bit actuel est 1 on doit faire le déplacement à gauche
srli t0, t0, 1					; On shift pour regarder si bouton suivant a été appuyé
andi t1, t0, 1					; On masque pour regarder seulement le bit de poid faible
beq t1, t7, move_paddle_left	; Si le bit actuel est 1 on doit faire le déplacement à droite

paddle_next:
addi t6, t6, 4					; On augmente l'offset de 4
srli t0, t0, 1
beq t6, t5, mv_paddle_end 		; Si l'offset est de 8 on a déjà bougé les deux paddles
br mv_paddle


move_paddle_left:
ldw t2, PADDLES(t6)				; On charge la position actuelle du paddle
beq t2, zero, paddle_next		; Si elle est zéro on peut pas aller plus à gauche
addi t2, t2, -1					; Sinon on peut soustraire 1
stw t2, PADDLES(t6)				; On sauve la nouvelle position
br paddle_next					; On passe au paddle suivant

move_paddle_right:
ldw t2, PADDLES(t6)				; Même chose que pour bouger le paddle à gauche
srli t0, t0, 1
addi s0, zero, 5				; Mais dans l'autre sens xD
beq t2, s0, paddle_next			; Si on a atteint la coordonnées y max on peut plus augmenter
addi t2, t2, 1					; Sinon on soustrait 1 à la coordonées y
stw t2, PADDLES(t6)				; Et on stocke la nouvelle coordonnées
br paddle_next

mv_paddle_end:
stw zero, BUTTONS+4(zero)		; On remet le edgecapture à zéro
ret


draw_paddle:
addi sp, sp, -4
stw ra, 4(sp)

addi t4, zero, 0				; t4 est le compteur de paddle
addi s1, zero, 8				; On stocke l'offset maximal des coordonnées des paddles
addi s0, zero, 0				; On pose la position x du deuxième paddle
ldw t0, PADDLES(zero)			; On charge les positions du premier paddle
addi t1, zero, 0				; On commence avec la valeur x = 0
addi t2, t0, 3					; Valeur maxi sur laquelle dessiné en y

draw_pixel:
bge t0, t2, next_paddle			; Si on a atteint le valeur de y maxi pour ce paddle on passe au suivant
add a0, s0, zero				; Sinon on met la valeur de x dans a0
add a1, t0, zero				; Et la nouvelle valeur de y dans a1
call set_pixel					; Et on dessine le pixel

next_y:
addi t0, t0, 1					; On incrémente la valeur de y de 1
br draw_pixel					; On continue à dessiner les pixels

next_paddle:
addi s0, zero, 11				; On met la position x du deuxième paddle à 11
addi t4, t4, 4					; On augmente le compteur de paddle
bge t4, s1, end_draw_paddle		; Si le compteur des paddles est 2 on a fini
ldw t0, PADDLES(t4)				; On charge la position du deuxième paddle
addi t2, t0, 3					; On set la valeur maximum de y pour ce paddle
br draw_pixel

end_draw_paddle:
ldw ra, 4(sp)					; On remet la bonne addresse de retour dans ra
addi sp, sp, 4
ret

move_ball:
ldw t0, BALL(zero)
ldw t1, BALL+8(zero)
ldw t2, BALL+4(zero)
ldw t3, BALL+0xC(zero)
add t0, t0, t1                  ; On ajoute la velocité à x
add t2, t2, t3                  ; On ajoute la velocité à y
stw t0, BALL(zero)              ; On stocke les nouvelles valeurs
stw t2, BALL+4(zero)            
ret


clear_leds:
addi t0, zero, 0x2000
stw zero, 0(t0)
stw zero, 4(t0)
stw zero, 8(t0)
ret


wait:
addi t0, zero, 0xFFF
slli t0, t0, 8

inner:
addi t0, t0, -1
bge t0, zero, inner

ret

init_game:

addi t0, zero, 3
addi t1, zero, 1
stw t1, BALL+8(zero)            ; Initialisation de la composante x
stw t1, BALL+0xC(zero)          ; Initialisation de la composante y
stw t0, BALL(zero)              ; Initialisation du vecteur velocité
stw t0, BALL+4(zero)
ret


font_data:
	.word 0x7E427E00 ; 0
	.word 0x407E4400 ; 1
	.word 0x4E4A7A00 ; 2
	.word 0x7E4A4200 ; 3
	.word 0x7E080E00 ; 4
	.word 0x7A4A4E00 ; 5
	.word 0x7A4A7E00 ; 6
	.word 0x7E020600 ; 7
	.word 0x7E4A7E00 ; 8
	.word 0x7E4A4E00 ; 9
	.word 0x7E127E00 ; A
	.word 0x344A7E00 ; B
	.word 0x42423C00 ; C
	.word 0x3C427E00 ; D
	.word 0x424A7E00 ; E
	.word 0x020A7E00 ; F