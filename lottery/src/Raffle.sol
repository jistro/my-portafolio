// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/**
* @title Contrato de "Rifa con causa"
* @author jistro.eth
* @notice Contrato para la rifa 
* @dev Implementa chainlink VRF
*/ 

contract Raffle is VRFConsumerBaseV2{
    error Raffle__notEnoughAVAX();
    error Raffle__failedToSendAVAX();
    error Raffle__raffleClosed();
    error Raffle__notEnoughTime();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 players, uint256 state);

    /** type declarations */

    enum RaffleState {
        OPEN,
        CALCULATING,
        CLOSED
    }

    /** State variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_ticketPrice;
    /// @dev Intervalo de tiempo en segundos
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    /// @dev Lista de participantes
    ///      el uso de payable es para poder enviarle
    ///      avax a la direccion
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;
    

    // para armar el nombre de la variable de evento debemos
        // 1. Cada palabra inicia con mayuscula
        // 2. Evitar el uso de caracteres especiales como guiones
        // 3. Cada accion debe ser en verbo imperativo

    /** Events */
    event EnetedRaffle(
        address indexed player
    );

    event PickedWinner(
        address indexed winner
    );

    event RequestedRaffleWinner(
        uint256 indexed requestId
    );

    constructor(
        uint256 _ticketPrice, 
        uint256 _interval, 
        address vrfCordinator, 
        bytes32 KeyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCordinator) {
        i_ticketPrice = _ticketPrice;
        i_interval = _interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCordinator);
        i_keyHash = KeyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }


    function enterRaffle() external payable {
        if (msg.value < i_ticketPrice) {
            revert Raffle__notEnoughAVAX();
        }

        if (s_raffleState != RaffleState.OPEN){
            revert Raffle__raffleClosed();
        }

        s_players.push(payable(msg.sender));

        emit EnetedRaffle(msg.sender);
    }

    /**
     * 
     *  @dev esta funcion hace la llamada los nodos de chainlink automation
     *  para ver si es tiempo de ejecutar esa funcion
     *  estos sigunetes parametros deben ser verdaderos para que se devuelva true
     *  1. el intervalo de tiempo que ha pasado desde que la rifa se ejecuto por ultima vez
     *  2. el estado de la rifa debe ser abierto
     *  3. el contrato tiene AVAX suficiente
     *  4. (implicito) La suscripcion de chainlink debe estar activa y fondeada con LINK
     */

    function checkUpkeep(
        bytes memory /*checkData*/
    ) public view returns (bool upkeepNeeded, bytes memory /*performData*/) {
        bool timeHasPassed = ( (block.timestamp - s_lastTimeStamp) >= i_interval );
        bool isOpen = (s_raffleState == RaffleState.OPEN);
        bool hasBalance = (address(this).balance >= i_ticketPrice);
        bool hasPlayers = (s_players.length > 0);
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "0x0");
    }

    //function pickWinner() external {

    // performUpkeep es la funcion que se llama chainlink automation
    function performUpkeep(bytes memory /*performData*/) external {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded){
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        
        if ( (block.timestamp - s_lastTimeStamp) <= i_interval ) {
            revert Raffle__notEnoughTime();
        }
            
        
        s_raffleState = RaffleState.CALCULATING;

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
        //s_raffleState = RaffleState.CLOSED;
    }

    function fulfillRandomWords(
        uint256 /*_requestId*/,
        uint256[] memory _randomWords
    ) internal override {
        uint256 indexOfWinner = _randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;

        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success)
            revert Raffle__failedToSendAVAX();

        emit PickedWinner(winner);
    }

    function getTicketPrice() external view returns (uint256) {
        return i_ticketPrice;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 _IndexPlayer) external view returns (address) {
        return s_players[_IndexPlayer];
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }
    
    function getTotalPlayers() external view returns (uint256) {
        return s_players.length;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }
}