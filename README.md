# ControleComReputacao
Um sistema que tenta diminuir um grande problema dos estoques hoje, a confiança do operador. Esse sistema visa diminuir problemas envolvendo má conduta.
# ControleComReputacao - Sistema de Reputação e Controle de Estoque On-Chain

## Objetivo

O projeto ControleComReputação é um protocolo Web3 para controle de estoque com sistema de reputação baseado em tokens ERC-20.

Funcionários possuem reputação representada pelo token TRUST.
Ações críticas exigem reputação mínima e infrações podem gerar penalidades.

---

# Problema Resolvido

Sistemas tradicionais de estoque possuem:
- pouca transparência;
- dificuldade de auditoria;
- centralização excessiva;
- baixa rastreabilidade de operações.

O projeto utiliza blockchain para registrar:
- movimentações;
- penalidades;
- governança;
- reputação de operadores.

---

# Arquitetura

## Contratos

### TrustToken (ERC-20)
Responsável pela reputação dos funcionários.

Funções:
- mint
- burn
- consulta de saldo

Transferências foram desabilitadas para impedir venda de reputação.

### ControleEstoque
Contrato principal do sistema.

Responsável por:
- cadastro de funcionários;
- cadastro de depósitos;
- cadastro de itens;
- movimentação de estoque;
- descarte;
- governança simplificada;
- aplicação de infrações.

---

# Governança

Infrações são aplicadas através de votação entre gestores.

Fluxo:
1. Gestor cria proposta;
2. Gestores votam;
3. Proposta é executada;
4. Tokens TRUST são queimados.

---

# Segurança

O projeto utiliza:
- OpenZeppelin;
- Solidity ^0.8.x;
- onlyOwner;
- modifiers;
- Slither para análise estática.

## Auditoria

Ferramenta utilizada:
- Slither

Resultado:
- Sem vulnerabilidades críticas identificadas.

---

# Deploy

Rede:
- Sepolia

Contrato:
- (https://sepolia.etherscan.io/tx/0x7ceeb9db949f67fadf416f7c17786b17793cc7239ede59b4db82db66f88e28a1)

Hash deploy:
- 0x7ceeb9db949f67fadf416f7c17786b17793cc7239ede59b4db82db66f88e28a1
---

# Demonstração

Fluxo demonstrado:
1. Cadastro de funcionário;
2. Mint de TRUST;
3. Cadastro de item;
4. Transferência entre depósitos;
5. Criação de infração;
6. Votação;
7. Execução da penalidade.

---

# Tecnologias

- Solidity
- OpenZeppelin
- Slither

---

# Autor

Eduardo XXXXX
