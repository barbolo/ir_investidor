# IR Investidor

IR Investidor é uma aplicação open source que pode rodar no seu computador para
calcular imposto de renda em operações de renda variável.

Em seu computador:

```bash
# instalação do software:
docker-compose pull # faz o download das imagens de Docker
docker-compose build # cria imagens de Docker do projeto
docker-compose run web bundle install # instala gems do projeto
docker-compose run web rake db:create db:migrate db:seed # cria e prepara o banco de dados

# execução da aplicação:
docker-compose up
```

Agora é só acessar o seguinte endereço em seu navegador:

[http://localhost:3060](http://localhost:3060/)


## Investimentos suportados

| Investimento            | Suportado |
|-------------------------|-----------|
| Ação (Normal/Daytrade)  | &#10004;  |
| Opção (Normal/Daytrade) | &#10004;  |
| FII (Normal/Daytrade)   | &#10004;  |
| Subscrição              | &#10004;  |


## Conversão de nota de corretagem para planilha

Gostaríamos de disponibilizar [scripts](scripts/) que ajudam a converter notas
de corretagem para planilhas.

No momento, é necessário conhecimentos básicos de programação para editar e
executar os scripts.

| Corretora                 | Suportada |
|---------------------------|-----------|
| [Clear](scripts/clear.rb) | &#10004;  |


Exemplo de como executar um script de conversão de nota de corretagem:

```bash
docker-compose run web bundle exec ruby scripts/clear.rb diretorio/com/pdfs/de/notas/de/corretagem/da/clear/
```

## Premissas

- O sistema não acessa nenhum dado pessoal (como nome, email ou CPF) e armazena
  dados de transações pelo menor tempo possível (somente enquanto o usuário
  calcula impostos);
- Deve ser fácil de rodar em qualquer computador (basta ter Docker instalado);
- Vendas de ações inferiores a 20 mil reais por mês são isentas de IR;
- Vendas geram IRRF de 1% (DAYTRADE) ou 0,005% (NORMAL);
- IRRF acumulado de um ano não pode ser compensado no ano seguinte;
- Data da liquidação está sendo ignorada;
- Veja mais premissas discutidas [aqui](https://github.com/barbolo/ir_investidor/wiki/Decis%C3%B5es-que-consideramos-para-calcular-Imposto-de-Renda).

## Contribuições

Se encontrar algum problema ou tiver alguma sugestão, você pode
[criar uma Issue](https://github.com/barbolo/ir_investidor/issues/new) no GitHub
para ser analisada.

Se desejar contribuir com o desenvolvimento deste software, basta enviar um
[Pull Request](https://github.com/barbolo/ir_investidor/pulls) para que a
alteração seja analisada e possivelmente integrada ao código fonte original.


## Licença de software

Este software utiliza a licença MIT. Em poucas palavras, você pode fazer o que
quiser com este software desde que você inclua a licença original em produtos
derivados e não responsabilize os autores originais por qualquer tipo de
prejuízo.

https://github.com/barbolo/ir_investidor/raw/master/LICENSE
