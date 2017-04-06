# IR Investidor

IR Investidor é uma aplicação web que auxilia investidores brasileiros (Pessoa
Física) a calcular Imposto de Renda com aplicações de renda fixa e variável.

## Investimentos suportados

> Work Still In Progress!

|Investimento          |Suportado|
|----------------------|---------|
|Ação - Normal         |&#10004; |
|Ação - Daytrade       |         |
|Opção                 |         |
|Fundo de Investimento |         |
|Fundo Imobiliário     |         |
|Futuro                |         |
|Renda Fixa            |         |
|Termo                 |         |


## Intenções

> Filosofias de desenvolvimento deste software

- Ser 100% automático
- Deve fornecer instruções claras de como instrumentalizar a declaração e/ou o
recolhimento de IR
- As regras de cáculos de impostos devem ser facilmente entendidas através do
código fonte
- Não deve guardar dados pessoais identificáveis (como nome ou CPF)
- Deve ser possível importar/exportar arquivo de backup com todos os dados
- Deve ser possível integrar provedores de armazenamento em nuvem para guardar
documentos usados nos cálculos, como notas de corretagem. Exemplos: Dropbox,
OneDrive, Google Drive.
- Fácil de instalar e de usar, inclusive por usuários leigos
- Suporte a qualquer sistema operacional que rode
[Docker](https://docs.docker.com/engine/installation/) (macOS, Windows,
GNU/Linux)
- O código fonte deve ser escrito em inglês. Nomes próprios não devem ser
traduzidos, como CBLC, CETIP ou RFB (Receita Federal do Brasil).


## Instruções para instalar o software

> O texto desta seção é um rascunho e ainda não está pronto.

```shell
docker-compose pull # faz o download das imagens de Docker
docker-compose build # cria imagens de Docker do projeto
docker-compose run web bundle install # instala gems do projeto
docker-compose run web rake db:create db:setup # cria e prepara o banco de dados
```


## Instruções para executar o software

> O texto desta seção é um rascunho e ainda não está pronto.

```shell
# o comando abaixo inicia os serviços da aplicação
docker-compose up
```

Agora é só acessar o seguinte endereço em seu navegador de Internet:

[http://localhost:3060](http://localhost:3060/)


## Contribuições

Se encontrar algum problema ou tiver alguma sugestão, você pode
[criar uma Issue](https://github.com/infosimples/ir_investidor/issues/new) no GitHub
para ser analisada.

Se desejar contribuir com o desenvolvimento deste software, basta enviar um
[Pull Request](https://github.com/infosimples/ir_investidor/pulls) para que a
alteração seja analisada e possivelmente integrada ao código fonte original.


## Licença de software

Este software utiliza a licença MIT. Em poucas palavras, você pode fazer o que
quiser com este software desde que você inclua a licença original em produtos
derivados e não responsabilize os autores originais por qualquer tipo de
prejuízo.

https://github.com/infosimples/ir_investidor/raw/master/LICENSE
