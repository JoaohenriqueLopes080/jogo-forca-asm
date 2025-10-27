.text
.globl main
main:	
	li $s6, 0		# $s6: Contador de Partes do Boneco Desenhadas (Erros)
	
	li $v0, 4		# Syscall para print_string
	la $a0, msg_inicio	# Endereço da mensagem de inicio
	syscall			# Imprime mensagem de inicio
	
	jal desenha_forca	# Funcao de desenho da forca
	
	# Captura o X e Y de retorno da forca (ponto de pendurar o boneco)
	move $s4, $v0		# $s4 = X inicial para o boneco
	move $s5, $v1		# $s5 = Y inicial para o boneco
	
	jal escolhePalavra	# Escolhe a palavra a ser adivinhada

	jal gameLoop		# Começa o jogo
	
	j fimPrograma
	
############## Bloco de Escolhe Palavra (Lógica de Arquivo) ##############
# Seleciona uma palavra aleatoriamente dentre todas da lista
escolhePalavra:
# $s3: File Descriptor (FD) do arquivo dados.dat
# $s1: Ponteiro BASE para a Palavra Chave (BUFFER)
# $s2: Ponteiro BASE para a Palavra Escondida (BUFFER_HIDDEN)
	# Abre o arquivo (Syscall 13)
    	li $v0, 13          	# Service code for open file
    	la $a0, NOME_ARQUIVO 	# endereço do arquivo
    	li $a1, 0           	# flag somente leitura
    	li $a2, 0           	# modo (não usado)
    	syscall             	# $v0 = File Descriptor (fd) ou -1 se erro
    	
    	# I/O: blez checa se $v0 <= 0 (cobre erro -1 e FD 0)
    	blez $v0, erroAbertura 
    	
    	move $s3, $v0		# copia o file descriptor (se for válido)

	li $v0, 42	# determina o código de syscall que gera um número aleatório entre 0 e n-1
	li $a0, 0	# id do gerador de numero aleatorio
	li $a1, 100	# limite superior do gerador (n)
	
	syscall		# gera o numero aleatorio
	move $s1,$a0	# move o numero aleatório para $s1 (este $s1 é o ÍNDICE ALEATÓRIO)
	
	li $s0, 0 	# inicializa contador com 0
procuraPalavra:
	li $v0, 14          	# serviço 14: leitura do arquivo
    	move $a0, $s3       	# $a0: descritor do arquivo (fd)
    	la $a1, BUFFER      	# endereço do buffer de destino
    	li $a2, 12      	# numero maximo de bytes para ler (12)
    	syscall			# le o texto do arquivo	
    	
    	beq $s0,$s1,encontrou	# finaliza o loop se o indice atual for o procurado
    	blez $v0, fimLoop	# checa se v0 é menor ou igual a zero (fim do arquivo ou erro de leitura) 
    	
	addi $s0,$s0,1		# incrementa o contador
	j procuraPalavra
encontrou:
	la $s1, BUFFER			# $s1 = Ponteiro BASE para a palavra chave (AGORA É O PONTEIRO!)
	la $s2, BUFFER_HIDDEN		# $s2 = Ponteiro BASE para a palavra escondida
	
	move $t0, $s1			# $t0 = Ponteiro de loop para a palavra chave (BUFFER)
	move $t2, $s2			# $t2 = Ponteiro de loop para a palavra escondida (BUFFER_HIDDEN)

	li $t1, 45			# $t1 = ASCII do hífen '-'
	
criaBufferHidden: 			
	lb $t3,0($t0)			# carrega o caractere atual ($t3)
	beq $t3,$zero,finalizaHidden	
	li $t4, 10			
	beq $t3,$t4,finalizaHidden	
	
	sb $t1,0($t2)			# insere hífen no $t2 (BUFFER_HIDDEN)
	
	addi $t0, $t0, 1		# avança ponteiro da chave
	addi $t2, $t2, 1		# avança ponteiro do hidden
	j criaBufferHidden		
finalizaHidden:
	sb $zero,0($t2)			# adiciona o terminador \0 no final
	
erroAbertura: # RÓTULO DE ERRO!
	# Se a abertura do arquivo falhou, o fluxo vem para cá e pula para o fechamento.

fimLoop:
	li $v0,16			# syscall 16: close file
	move $a0,$s3			# $a0 recebe o file descriptor ($s3)
	syscall
	
	jr $ra
############## Bloco de lógica do jogo (GameLoop) ##############
# $s7: Chute do Jogador (Letra)
# $s0: Contador de Ocorrências da Letra
gameLoop:
	# No início de cada rodada, $s2 é usado corretamente para imprimir a palavra.
	
	li $v0, 4		
	la $a0, msg_palavra	
	syscall			
	
	li $v0, 4		
	move $a0,$s2		# Imprime usando $s2 (ponteiro de INÍCIO)
	syscall			
	
	li $v0, 4		
	la $a0, msg_prompt	
	syscall			
	
	li $v0, 12		
	syscall			
	move $s7,$v0		
	
	beq $s7,0,voltaMain
	li $s0, 0		

	# --- CORREÇÃO: Cria ponteiros TEMPORÁRIOS para a checagem ---
	move $t0, $s1		# $t0: Ponteiro atual da PALAVRA CHAVE (BUFFER)
	move $t1, $s2		# $t1: Ponteiro atual da PALAVRA ESCONDIDA (BUFFER_HIDDEN)
	
checaLetra:
	lb $t3,($t0)			
	beq $t3,0,fimChecagem		
	li $t4, 10			
	beq $t3,$t4,fimChecagem		
	bne $t3,$s7,incrementa_t	# Se a letra for diferente, pula
	
estaNaPalavra:
	addi $s0,$s0,1			
	sb $s7,0($t1)			# Escreve usando $t1, que aponta para o lugar correto
incrementa_t:
	addi $t0,$t0,1			# Incrementa ponteiro da palavra chave (t0)
	addi $t1,$t1,1			# Incrementa ponteiro da palavra escondida (t1)
	j checaLetra
	
fimChecagem:
	beq $s0,$zero,naoEstaNaPalavra
	la $t0, BUFFER_HIDDEN     
    	li $t1, 45                
checaVitoria:
    	lb $t2, 0($t0)            
    	beq $t2, $zero, vitoria   
    	beq $t2, $t1, continuaJogo 
    	addi $t0, $t0, 1          
    	j checaVitoria
continuaJogo:
    	j gameLoop                
naoEstaNaPalavra:
	
	move $a0,$s6		
	
	addiu $sp,$sp,-4	
	sw $ra,0($sp)		
	
	jal drawParte		
	
	lw $ra,0($sp)		
	addiu $sp,$sp,4		
	
	addi $s6,$s6,1		
	beq $s6,6,gameOver	
	j gameLoop
voltaMain:
	jr $ra
vitoria:
	la $a0,msg_vitoria
	li $v0,4
	syscall
	j printPalavra
gameOver:
	la $a0,msg_gameover
	li $v0,4
	syscall
	# Adicione JUMP explícito para o printPalavra
	j printPalavra
	
printPalavra:
	la $s1, BUFFER
	move $a0,$s1     # Usa o ponteiro redefinido
	li $v0,4
	syscall
	
	# ADICIONE JUMP para o fimPrograma
	j fimPrograma
	
fimPrograma:
	# encerra o programa
	li $v0, 10
	syscall
	
############## Lógica de Desenho (ROTEADOR drawParte) ##############
# $s4: X atual para desenho (posição) - Ponto de início da cabeça
# $s5: Y atual para desenho (posição) - Ponto de início da cabeça
drawParte:
	# Prologo: Salva $ra e $a0
	addiu $sp,$sp,-8	
	sw $ra,4($sp)
	sw $a0,0($sp) 
	
	# Os argumentos $a0 (X) e $a1 (Y) serão definidos para cada parte.
	# Por padrão, são $s4 e $s5 (a última coordenada de desenho - cintura, após o corpo)
	move $t0, $s4 		# X (base)
	move $t1, $s5 		# Y (base)
	
	lw $t2, 0($sp) 		# $t2 = número da parte (0 a 5)
	
	# Roteia para a função correta.
	beq $t2, 0, desenha_cabeca_router	# 0: Cabeça (usa $s4/$s5 atual)
	beq $t2, 1, desenha_corpo_router	# 1: Corpo (usa $s4/$s5 atualizado pela cabeça)
	beq $t2, 2, desenha_membro_esq_router	# 2: Braço Esquerdo (usa $s4/$s5 - 5)
	beq $t2, 3, desenha_membro_dir_router	# 3: Braço Direito (usa $s4/$s5 - 5)
	beq $t2, 4, desenha_perna_esq_router	# 4: Perna Esquerda (usa $s4/$s5)
	beq $t2, 5, desenha_perna_dir_router	# 5: Perna Direita (usa $s4/$s5)
	
	j drawParte_epilogo 

desenha_cabeca_router:
	move $a0, $t0 		# X (base)
	move $a1, $t1 		# Y (base)
	jal desenha_cabeca 
	move $s4, $v0 		# Atualiza X para o corpo
	move $s5, $v1 		# Atualiza Y para o corpo
	j drawParte_epilogo
desenha_corpo_router:
	move $a0, $t0 		# X (base)
	move $a1, $t1 		# Y (base)
	jal desenha_corpo
	move $s4, $v0 		# Atualiza X para a cintura (início de braços/pernas)
	move $s5, $v1 		# Atualiza Y para a cintura (início de braços/pernas)
	j drawParte_epilogo
desenha_membro_esq_router:
	move $a0, $t0 		# X (base)
	addi $a1, $t1, -9	# Y (base) 
	jal desenha_membro_esq 
	# Não atualiza $s4/$s5. Ele deve permanecer a cintura.
	j drawParte_epilogo
desenha_membro_dir_router:
	move $a0, $t0 		# X (base)
	addi $a1, $t1, -9	# Y (base)
	jal desenha_membro_dir 
	# Não atualiza $s4/$s5. Ele deve permanecer a cintura.
	j drawParte_epilogo
desenha_perna_esq_router:
	move $a0, $t0 		# X (base)
	addi $a1, $t1, -3	# MUDE para subir o início da perna
	jal desenha_membro_esq # Reutiliza a função de membro esquerdo
	# Não atualiza $s4/$s5. Ele deve permanecer a cintura.
	j drawParte_epilogo
desenha_perna_dir_router:
	move $a0, $t0 		# X (base)
	addi $a1, $t1, -3	# MUDE para subir o início da perna
	jal desenha_membro_dir # Reutiliza a função de membro direito
	# Não atualiza $s4/$s5. Ele deve permanecer a cintura.
	j drawParte_epilogo

drawParte_epilogo:
	# Epilogo: Restaura $ra e $a0.
	lw $a0,0($sp)		
	lw $ra,4($sp)		
	addiu $sp,$sp,8		
	jr $ra

############## Código de Desenho (Funções Simples e Funcionais) ##############

put_pixel:
# Funcao para desenhar um pixel. Recebe $a0 (X), $a1 (Y), $a2 (COR).
# *** CÓDIGO CORRIGIDO ***
            la    $t0, dm_largura          # $t0 <- numero de pixels em uma unidade de pixels
            lw    $t1, dm                  # Usa LW para carregar o VALOR (0x10000000)
            lw    $t2, 0($t0)              # $t2 <- numero de unidades de pixel na largura
            sll   $t3, $a0, 2              # $t3 <- x * 4, onde 4 eh numero de bytes por cor
            sll   $t4, $a1, 2              # $t4 <- y * 4, onde 4 eh numero de bytes por cor
            mul   $t4, $t4, $t2            # $t4 <- y * 4 * dm_largura
            add   $t4, $t4, $t3            # $t4 <- y * 4 * dm_largura + x*4
            add   $t4, $t4, $t1            # $t4 <- y * 4 * dm_largura + x*4 + dm_base_address
            sw    $a2, 0($t4)              # faz o pixel nas coordenadas (x,y) ter a cor RGB de $a2
fim_put_pixel:
            jr    $ra

desenha_forca: 
# prologo
	    addi  $sp, $sp, -4
	    sw    $ra, 0($sp)
# corpo do procedimento (versão original de loops simples)
	    li    $s0, 0
	    li    $a0, 15                      # posicao x inicial da forca
	    li    $a1, 75                      # posicao y inicial da forca
	    li    $a2, 0x00baba00              # cor amarela
haste_vertical:
	    sub   $a1, $a1, 1                  
	    jal   put_pixel                    
	    add   $s0, $s0, 1
	    blt   $s0, 55, haste_vertical
haste_horizontal:
	    add   $a0, $a0, 1                  
	    jal   put_pixel                    
	    sub   $s0, $s0, 1
	    bgt   $s0, 20, haste_horizontal
	    li    $s0, 0
segura_boneco:
	    add   $a1, $a1, 1                  
	    jal   put_pixel                    
	    add   $s0, $s0, 1                  
	    blt   $s0, 5, segura_boneco
	    move  $v0, $a0                     # Retorna X final (Ponto de pendurar)
	    move  $v1, $a1                     # Retorna Y final (Ponto de pendurar)
# epilogo
	    lw    $ra, 0($sp)
	    addi  $sp, $sp, 4
	    jr    $ra
	    
	    
desenha_cabeca:
	    addi  $sp, $sp, -4
	    sw    $ra, 0($sp)
	    
	    li    $s0, 0x00FFFFFF # Cor
	    
	    # Registradores usados para constantes e centro
	    li    $t5, 5          # Raio R
	    li    $t6, 25         # R^2
	    move  $t7, $a0        # Xc
	    add   $t8, $a1, $t5   # Yc
	    
	    # Registradores de loop
	    sub   $t0, $t7, $t5   # X_start (X atual)
	    sub   $t1, $t8, $t5   # Y_start (Y atual)
	    add   $t2, $t7, $t5   # X_end
	    add   $t3, $t8, $t5   # Y_end
	    
loop_y:
	    bgt   $t1, $t3, fim_cabeca_draw
	    sub   $t0, $t7, $t5   # Reinicia X_atual
loop_x:
	    bgt   $t0, $t2, next_y
	    
	    # Checagem do Círculo
	    sub   $t4, $t0, $t7   # dx
	    sub   $t9, $t1, $t8   # dy
	    mul   $t4, $t4, $t4   # dx^2
	    mul   $t9, $t9, $t9   # dy^2
	    add   $t4, $t4, $t9   # dist^2
	    
	    bgt   $t4, $t6, incrementa_x
	    
	    # --- Salva registradores críticos antes de JAL put_pixel ---
	    # $t0 a $t9 (exceto $t6, $t5, $s0)
	    addi  $sp, $sp, -32  # Espaço para 8 registradores (t0, t1, t2, t3, t4, t7, t8, t9)
	    sw    $t0, 0($sp)
	    sw    $t1, 4($sp)
	    sw    $t2, 8($sp)
	    sw    $t3, 12($sp)
	    sw    $t4, 16($sp)
	    sw    $t7, 20($sp)
	    sw    $t8, 24($sp)
	    sw    $t9, 28($sp)

	    move  $a0, $t0
	    move  $a1, $t1
	    move  $a2, $s0
	    jal   put_pixel
	    
	    # --- Restaura registradores críticos ---
	    lw    $t0, 0($sp)
	    lw    $t1, 4($sp)
	    lw    $t2, 8($sp)
	    lw    $t3, 12($sp)
	    lw    $t4, 16($sp)
	    lw    $t7, 20($sp)
	    lw    $t8, 24($sp)
	    lw    $t9, 28($sp)
	    addi  $sp, $sp, 32
	    
incrementa_x:
	    addiu $t0, $t0, 1
	    j     loop_x
next_y:
	    addiu $t1, $t1, 1
	    j     loop_y
	    
fim_cabeca_draw:
	    move  $v0, $t7
	    move  $v1, $t3
	    
	    lw    $ra, 0($sp)
	    addi  $sp, $sp, 4
	    jr    $ra       
desenha_membro_esq: # (Braço ou Perna Esquerda)
# prologo
	    addi $sp, $sp, -4
	    sw   $ra, 0($sp)
# corpo do procedimento (versão original de loops simples)
	    li   $s0, 0
	    add  $a1, $a1, 1
mbresq:
	    li   $a2, 0x00FFFFFF              # cor branca
	    jal  put_pixel                    
	    sub  $a0, $a0, 1                  
	    add  $a1, $a1, 1                  
	    add  $s0, $s0, 1                  
	    blt  $s0, 8, mbresq
# epilogo
	    lw   $ra, 0($sp)
	    addi $sp, $sp, 4
	    jr   $ra
	    
desenha_membro_dir: # (Braço ou Perna Direita)
# prologo
	    addi $sp, $sp, -4
	    sw   $ra, 0($sp)
# corpo do procedimento (versão original de loops simples)
	    li   $s0, 0
	    add  $a1, $a1, 1
mbrdir:
	    li   $a2, 0x00FFFFFF              # cor branca
	    jal  put_pixel                    
	    add  $a0, $a0, 1                  
	    add  $a1, $a1, 1                  
	    add  $s0, $s0, 1                  
	    blt  $s0, 8, mbrdir
#epilogo
	    lw   $ra, 0($sp)
	    addi $sp, $sp, 4
	    jr   $ra
	    
desenha_corpo:
# prologo
	    addi $sp, $sp, -4
	    sw   $ra, 0($sp)
# corpo do procedimento (versão original de loops simples)
	    li   $s0, 0
	    add  $a1, $a1, 1 # Ponto de início Y+1 (abaixo da cabeça)
corpo:
	    li   $a2, 0x00FFFFFF              # cor branca
	    jal  put_pixel
	    add  $a1, $a1, 1                 # desenha uma linha vertical 
	    add  $s0, $s0, 1                 
	    blt  $s0, 10, corpo
	    move $v0, $a0                    # Retorna X (não muda)
	    move $v1, $a1                    # Retorna Y (fim do corpo)
# epilogo
	    lw   $ra, 0($sp)
	    addi $sp, $sp, 4
	    jr   $ra


.data
	# Variáveis do t1.asm
	BUFFER: 	.space 13
	BUFFER_HIDDEN:	.space 13
	NOME_ARQUIVO:	.asciiz "C:\\Users\\Joao\\Downloads\\jogodaforca\\dados.dat"
	msg_inicio:	.asciiz "\n ===== Jogo da Forca Assembly ====="
	msg_palavra:	.asciiz "\nPalavra: "
	msg_prompt:	.asciiz "\nChute uma letra: "
	msg_vitoria:	.asciiz "\n\n ======= VITORIA =======\nA palavra era:\n"
	msg_gameover:	.asciiz "\n\n ======= GAME OVER =======\nA palavra era:\n"
	partes: 	.word 0
	
	# Variáveis de Configuração do MARS Bitmap Display
	dm:  .word 0x10000000 # Endereço base da memória de vídeo
	dm_largura: .word 128
	dm_altura: .word 128
	dm_x_min: .word 0
	dm_y_min: .word 0
	dm_x_max: .word 127
	dm_y_max: .word 127
	
	sprite: 
