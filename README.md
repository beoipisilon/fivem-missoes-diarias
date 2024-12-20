# fivem-missoes-diarias

Este projeto implementa um sistema de missões diárias para servidores **FiveM**, utilizando cache local e integração com banco de dados MySQL via **oxmysql**. Ele oferece funcionalidades como criação e resgate de missões, além de notificações via webhook.

## Funcionalidades

- **Gerenciamento de Usuários**
  - Criação de cache local para usuários.
  - Sincronização com o banco de dados ao conectar e desconectar.
  
- **Sistema de Missões**
  - Cache local para missões disponíveis.
  - Criação de missões e inserção automática no banco de dados.
  - Funcionalidades para iniciar e resgatar missões.
  - Restrição para iniciar missões antes de 24 horas após o último resgate.

- **Integração com Webhooks**
  - Notificações para eventos de missão (início, finalização e resgate).

## Estrutura do Projeto

- **Cache**
  - `Users.cache`: Armazena informações dos usuários.
  - `Missions.cache`: Armazena informações das missões.

- **Banco de Dados**
  - Tabelas:
    - `daily_missions`: Informações das missões dos usuários.
    - `missions`: Configuração das missões disponíveis.

- **Webhooks**
  - Integração para registrar logs de eventos importantes.

## Requisitos

- **FiveM Framework**
  - Suporte para vRP ou similar.
  
- **Banco de Dados**
  - MySQL configurado com **oxmysql**.

## Configuração

1. **Banco de Dados**
   - As tabelas necessárias são criadas automaticamente

2. **Configuração de Webhooks e Nomes**
   - Adicione os links de webhook no arquivo de configuração `shared/shared.lua`:
     ```lua
     Config.Webhooks = {
         create = "LINK_DO_WEBHOOK_CREATE",
         claim = "LINK_DO_WEBHOOK_CLAIM",
         start = "LINK_DO_WEBHOOK_START",
         finish = "LINK_DO_WEBHOOK_FINISH"
     }
     ```
    - Adicione os nomes das missões no arquivo de configuração `shared/shared.lua`:
    - Esses nomes são usados para identificar as missões no client.lua na função initMission.
    - Exemplo:
     ```lua
     Config.Names = {
        ["online"] = true,
        ["offline"] = true
     }
     ```

3. **Dependências**
   - Certifique-se de que o **oxmysql** está instalado e configurado no seu servidor.

## Comandos Disponíveis

- `/criarmissao`: Cria uma nova missão (exemplo incompleto no código fornecido).

## Exemplo de Uso

1. **Conectar Jogador**
   - O jogador é automaticamente registrado no cache e no banco de dados, caso não exista.

2. **Gerenciar Missões**
   - **Iniciar**: O jogador inicia uma missão disponível.
   - **Resgatar**: Recebe a recompensa por uma missão concluída.

3. **Webhooks**
   - Logs automáticos são enviados para os webhooks configurados em eventos de missão.

## Observações

- As missões só podem ser reiniciadas após 24 horas do último resgate.
- Utilize a função `Notify` para exibir mensagens ao jogador.

## Demo

Confira o vídeo de demonstração: [Assista aqui](https://youtu.be/Yc9QYB3S_Do)