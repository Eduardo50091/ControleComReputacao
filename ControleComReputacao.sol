// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.6.0
pragma solidity ^0.8.30;

//Criação do token ERC-20 "TRUST"-------------------------------------------------------------------------------------------------------------------------------------------------------
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract TrustToken is ERC20, Ownable {
    constructor(address initialOwner)
        ERC20("TrustToken", "TRUST")
        Ownable(initialOwner)
    {}

    function mint(address destino, uint256 quantidade) public onlyOwner {
        _mint(destino, quantidade);
    }

    function burn(address usuario, uint256 quantidade) public onlyOwner {
        _burn(usuario, quantidade);
    }

    function transfer(address, uint256) public pure override returns (bool){
        revert("Transferencias desabilitadas");
    }

    function transferFrom(address, address, uint256) public pure override returns (bool){
        revert("Transferencias desabilitadas");
    }

    function approve(address, uint256) public pure override returns (bool) {
        revert("Aprovacoes desabilitadas");
    }

    function allowance(address, address) public pure override returns (uint256) {
        return 0;
    }
}



// Definir elementos necessários antes de chamar as funções------------------------------------------------------------------------------------------------------------------------------
//Aqui criei o contrato principal, é através dele que vamos controlar o estoque.
contract ControleEstoque is Ownable {
    //Variável que guarda o endereço do token.
    TrustToken public immutable Trust;
    
    //define que vai ser o dono do contrato, o dono vai ser a carteira que fez o deploy.
    constructor(address enderecoToken) Ownable(msg.sender){
        // conecta o contrato ao token TRUST
        Trust = TrustToken(enderecoToken);}
    
    //define os cargos possíveis
    enum Cargo {operador, gestor}

    //---------------------------------------------------------------------------------------------------------
    //Estruturas:

    //Agora vamos fazer um 'Struct' para cadastrar funcionários.
    struct Funcionario {
        address carteira;
        string nome;
        Cargo cargo;
        uint256 matricula;
        bool ativo;
        
    }
    //Agora struct para cadastrar depósitos.
    struct Deposito {
        string nome;
        bool ativo;
    }
    //Struct para os itens
    struct Item {
        string nome;
        bool ativo;
    }

    struct TipoInfracao {
        // nome infração
        string nome;
        // quantidade de tokens perdidos
        uint256 penalidade;
        // infração ativa?
        bool ativo;
    }

    struct RegistroInfracao {
        // id infração
        uint256 idInfracao;
        // data aplicação
        uint256 timestamp;
    }

    struct PropostaInfracao {
    address funcionario;
    uint256 idInfracao;
    uint256 votosFavor;
    bool executada;
    address proponente;
    uint256 criadaEm;
}
    //---------------------------------------------------------------------------------------------------------
    //Contadores:

    uint256 public totalDepositos;
    uint256 public totalItens;
    uint256 public totalTiposInfracao;
    uint256 public constant votosNecessarios = 2;
    
    //---------------------------------------------------------------------------------------------------------
    //Mapeamentos:

    mapping (address => Funcionario) public funcionarios;
    mapping (uint256 => Deposito) public depositos;
    mapping (uint256 => Item) public itens;
    //Esse mapping me ajuda a ver quais itens e quantos possuem em determinado depósito.
    mapping (uint256 => mapping (uint256 => uint256)) public estoque;
    mapping(uint256 => TipoInfracao) public tiposInfracao;
    mapping(address => RegistroInfracao[]) public historicoInfracoes;
    mapping(uint256 => PropostaInfracao) public propostas;
    uint256 public totalPropostas;
    mapping(uint256 => mapping(address => bool)) public votou;
    

    //---------------------------------------------------------------------------------------------------------
    //modificadores:

    modifier apenasGestor() {
        require(
            funcionarios[msg.sender].ativo,
            "Gestor inativo"
        );

        require(
            funcionarios[msg.sender].cargo == Cargo.gestor,
            "Apenas gestores"
        );

        _;
    }

    modifier FuncionarioAtivo() {
        require(
            funcionarios[msg.sender].ativo,
            "Operador inativo"
        );
        _;
    }

    modifier depositoExiste(uint256 depositoId) {
        require(
            depositos[depositoId].ativo,
            "Deposito invalido"
        );
        _;
    }

    modifier itemExiste(uint256 itemId) {
        require(
            itens[itemId].ativo,
            "Item invalido"
        );
        _;
    }

    modifier infracaoExiste(uint256 infracaoId) {
        require(
            tiposInfracao[infracaoId].ativo,
            "Infracao invalida"
        );
        _;
    }
    //---------------------------------------------------------------------------------------------------------
    //Eventos:

    event FuncionarioCadastrado(
        address indexed carteira,
        string nome,
        uint256 matricula,
        Cargo cargo
    );

    event DepositoCadastrado(
        uint256 depositoId,
        string nome
    );

    event ItemCadastrado(
        uint256 itemId,
        string nome
    );

    event QuantidadeAlterada(
        uint256 depositoId,
        uint256 itemId,
        uint256 quantidade
    );

    event TransferenciaRealizada(
        uint256 itemId,
        uint256 origem,
        uint256 destino,
        uint256 quantidade
    );

    event DescarteRealizado(
        uint256 itemId,
        uint256 depositoId,
        uint256 quantidade
    );

    event OperacaoExtornada(
        uint256 depositoId,
        uint256 itemId,
        uint256 quantidade,
        address gestor
    );

    event TipoInfracaoCadastrado(
        uint256 idInfracao,
        string nome,
        uint256 penalidade
    );

    event InfracaoAplicada(
        address funcionario,
        string motivo,
        uint256 perdaTokens
    );

    event PropostaCriada(
        uint256 propostaId,
        address funcionario,
        uint256 idInfracao
    );

    event VotoRegistrado(
        uint256 propostaId,
        address gestor
    );

    event PropostaExecutada(
        uint256 propostaId
    );
//---Agora definição das funções----------------------------------------------------------------------------------------------------------------------------------------------------------
//---Funções para todo tipo de cadastro----------------------------------------------------------------------------------------------------------------------------
    //Função para cadastrar funcionário.--------------------------------------------------------------------------------
    function CadastroDeOperador(address carteira, string memory nome, uint256 matricula, Cargo cargo) public onlyOwner {
        require(
            !funcionarios[carteira].ativo,
            "Funcionario ja cadastrado"
        );

        funcionarios[carteira] = Funcionario({carteira: carteira, nome: nome, matricula: matricula, cargo: cargo, ativo: true});
        Trust.mint(carteira, 100 ether);
        emit FuncionarioCadastrado(carteira, nome, matricula, cargo);
        
    }

//---Função para cadastrar Item .--------------------------------------------------------------------------------
    function cadastrarItem(string memory nome) public FuncionarioAtivo {
        require(
            Trust.balanceOf(msg.sender) >= 90 ether,
            "Reputacao insuficiente"
        );
    
        // aumenta contador
        totalItens++;

        // cria item
        itens[totalItens] = Item({nome: nome, ativo: true});
        emit ItemCadastrado(totalItens, nome);
    }

//---Função para cadastrar Depósito.--------------------------------------------------------------------------------
    function cadastrarDeposito(string memory nome) public apenasGestor {
        // aumenta contador
        totalDepositos++;

        // cria depósito
        depositos[totalDepositos] = Deposito({nome: nome, ativo: true});

        // Emite que o depósito foi cadastrado.
        emit DepositoCadastrado(totalDepositos, nome);
    }

    //Função para cadastrar a infração .----------------------------------------------------------------
    function cadastrarTipoInfracao(string memory nome, uint256 penalidade) public onlyOwner {
        // aumenta contador
        totalTiposInfracao++;

        // cria infração
        tiposInfracao[totalTiposInfracao] = TipoInfracao({nome: nome, penalidade: penalidade, ativo: true});
        emit TipoInfracaoCadastrado(totalTiposInfracao, nome, penalidade);
    }
//---Funções para ações nos depósitos-----------------------------------------------------------------------------------------------------------------------------
    //Função para alterar quantidade de itens .----------------------------------------------------------------
    function alterarQuantidade( uint256 depositoId, uint256 itemId, uint256 quantidade) public FuncionarioAtivo depositoExiste(depositoId) itemExiste(itemId) {
        require(
            Trust.balanceOf(msg.sender) >= 90 ether,
            "Reputacao insuficiente"
        );

        // altera estoque
        estoque[depositoId][itemId] = quantidade;

        emit QuantidadeAlterada(
            depositoId,
            itemId,
            quantidade
        );
    }

    //Função para trasnferir de um depósito á outro .----------------------------------------------------------------
    function transferirEntreDepositos(uint256 origem, uint256 destino, uint256 itemId, uint256 quantidade) public FuncionarioAtivo depositoExiste(origem) depositoExiste(destino) itemExiste(itemId) {
        require(
            Trust.balanceOf(msg.sender) >= 50 ether,
            "Reputacao insuficiente"
        );

        // verifica estoque
        require(
            estoque[origem][itemId] >= quantidade,
            "Estoque insuficiente"
        );

        // remove origem
        estoque[origem][itemId] -= quantidade;
        // adiciona destino
        estoque[destino][itemId] += quantidade;
        emit TransferenciaRealizada(itemId, origem, destino, quantidade);
    }

    //Função para descartar item .----------------------------------------------------------------
    function descartarItem(uint256 depositoId, uint256 itemId, uint256 quantidade) public FuncionarioAtivo depositoExiste(depositoId) itemExiste(itemId){
        require(
            Trust.balanceOf(msg.sender) >= 90 ether,
            "Reputacao insuficiente"
        );

        // verifica estoque
        require(
            estoque[depositoId][itemId] >= quantidade,
                "Quantidade invalida"
        );

        // remove estoque
        estoque[depositoId][itemId] -= quantidade;

        emit DescarteRealizado(itemId, depositoId, quantidade);
    }

    //Função para extornar quantidade de item .----------------------------------------------------------------
    function extornarOperacao(uint256 depositoId, uint256 itemId, uint256 quantidade) public apenasGestor{
        // devolve item
        estoque[depositoId][itemId]
            += quantidade;

            emit OperacaoExtornada(
                depositoId,
                itemId,
                quantidade,
                msg.sender
            );
    }

//---Funções para ações nos depósitos-----------------------------------------------------------------------------------------------------------------------------
    //Função para criar proposta para infração .----------------------------------------------------------------
    function criarPropostaInfracao(address funcionario, uint256 idInfracao) public apenasGestor infracaoExiste(idInfracao){
        require(
            funcionarios[funcionario].ativo,
            "Funcionario invalido"
        );

        require(
            tiposInfracao[idInfracao].ativo,
            "Infracao invalida"
        );

        totalPropostas++;

        propostas[totalPropostas] = PropostaInfracao({
            funcionario: funcionario,
            idInfracao: idInfracao,
            votosFavor: 0,
            executada: false,
            proponente: msg.sender,
            criadaEm: block.timestamp
        });

        emit PropostaCriada(
            totalPropostas,
            funcionario,
            idInfracao
        );
    }

    //Função para gerenciar a votação .----------------------------------------------------------------
    function votarProposta(uint256 propostaId) public apenasGestor {
        PropostaInfracao storage proposta = propostas[propostaId];
        require(
            !proposta.executada,
            "Proposta encerrada"
        );

        require(
            !votou[propostaId][msg.sender],
            "Gestor ja votou"
        );

        require(
            block.timestamp <= proposta.criadaEm + 3 days,
            "Prazo encerrado"
        );

        votou[propostaId][msg.sender] = true;

        proposta.votosFavor++;

        emit VotoRegistrado(
            propostaId,
            msg.sender
        );
    }

    //Função para executar oque foi votado--------------------------------------------------------------------------
    function executarProposta(uint256 propostaId) public apenasGestor {
        PropostaInfracao storage proposta = propostas[propostaId];
        require(
            !proposta.executada,
            "Ja executada"
        );

        require(
            proposta.votosFavor >= votosNecessarios,
            "Votos insuficientes"
        );

        TipoInfracao memory infracao =
            tiposInfracao[proposta.idInfracao];

        require(
            infracao.ativo,
            "Infracao invalida"
        );

        proposta.executada = true;

        historicoInfracoes[
            proposta.funcionario
        ].push(
            RegistroInfracao({
                idInfracao: proposta.idInfracao,
                timestamp: block.timestamp
            })
        );

        Trust.burn(
            proposta.funcionario,
            infracao.penalidade * 1 ether
        );

        emit PropostaExecutada(
            propostaId
        );

        emit InfracaoAplicada(
            proposta.funcionario,
            infracao.nome,
            infracao.penalidade
        );
    }
//---Funções para consutas-----------------------------------------------------------------------------------------------------------------------------

    function consultarReputacao(address funcionario) public view returns(uint256)
    {
        return Trust.balanceOf(funcionario) / 1 ether;
    }


    function consultarEstoque(uint256 depositoId, uint256 itemId) public view returns(uint256){
        return estoque[depositoId][itemId];
    }

    function consutarHistoricoInfracoes(address _funcionario) public view returns(RegistroInfracao[] memory){
        return historicoInfracoes[_funcionario];
    }
}
