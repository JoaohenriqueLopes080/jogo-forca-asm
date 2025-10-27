Como Compilar:

Para que o arquivo de dados seja compilado corretamente, o software MARS deve ser executado de dentro da pasta jogodaforca.
No software MARS, abra o arquivo t1.asm
Na aba de opções no canto superior esquerdo da tela, clique em Settings e habilite a opção "Assemble all files in directory"
Após isso, pode compilar normalmente.

Como Jogar:

Após a compilação, deve abrir a ferramenta Bitmap Display do software MARS, colocar : 
          unit width: 4
          unit height: 4
          best adress for display : 0x10000000 (Global Data)
e clicar em "Connect to MIPS".

Então, pelo terminal, deve chutar as letras, que devem ser inseridas EM MAIÚSCULO para serem identificadas corretamente.
