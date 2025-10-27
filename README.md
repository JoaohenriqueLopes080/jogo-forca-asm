# Jogo da Forca 
## 🛠️ Como Compilar

Para garantir a compilação correta do arquivo de dados, siga as instruções abaixo:

1.  **Localização:** O software **MARS** deve ser executado *de dentro* da pasta `jogodaforca`.
2.  **Abrir Arquivo:** No software MARS, abra o arquivo principal:
    * `t1.asm`
3.  **Configurações:** Acesse as opções no canto superior esquerdo da tela:
    * Clique em **Settings**.
    * **Habilite** a opção: **"Assemble all files in directory"**.
4.  **Compilação:** Após habilitar a opção, você pode compilar o código normalmente.

## 🕹️ Como Jogar

Depois de compilar o código, configure o display e interaja com o jogo pelo terminal:

### 🖥️ Configuração do Bitmap Display

1.  Abra a ferramenta **Bitmap Display** do software MARS.
2.  Configure os seguintes parâmetros:
    * **Unit Width:** `4`
    * **Unit Height:** `4`
    * **Base Address for Display:** `0x10000000` (Global Data)
3.  Clique em **"Connect to MIPS"**.

### ⌨️ Interação no Terminal

1.  O jogo será executado.
2.  Pelo terminal, você deve chutar as letras.
3.  **Atenção:** As letras devem ser inseridas **EM MAIÚSCULO** para serem identificadas corretamente pelo programa.

***
