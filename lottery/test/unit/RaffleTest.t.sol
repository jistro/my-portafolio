// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test{
    /* events for the contracts to test */
    event EnetedRaffle(
        address indexed player
    );

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 ticketPrice;
    uint256 interval;
    address vrfCordinator; 
    bytes32 KeyHash;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    address public PLAYER1 = makeAddr("player1");

    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle,helperConfig) = deployer.run();
        vm.deal(PLAYER1, STARTING_BALANCE);
        
        (
            ticketPrice, 
            interval,
            vrfCordinator, 
            KeyHash,
            subscriptionId,
            callbackGasLimit,
            /*link*/,
            // deployerKey
        ) = helperConfig.activeNetworkConfig();
        
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function testRaffleInitializesInOpenState()  public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    //////////////////////////////////////////////////////////////////////////
    // Enter the raffle                                                     //
    //////////////////////////////////////////////////////////////////////////
    
    function testRffleRevertWhenYouDonPlayEnough() public {
        // 1. Arrange
        vm.startPrank(PLAYER1);
        // 2. Act
        vm.expectRevert(Raffle.Raffle__notEnoughAVAX.selector);
        raffle.enterRaffle();
        // 3. Assert
        vm.stopPrank();
    }

    function testRffleRecordsPlayerWhenTheyEnter() public {
        vm.startPrank(PLAYER1);
        raffle.enterRaffle{value: ticketPrice}();
        address aux_playerRecorded = raffle.getPlayer(0);
        assert(aux_playerRecorded == PLAYER1);
        vm.stopPrank();
    }

    function testEmitEventOnEntrance() public {
        vm.startPrank(PLAYER1);
            // expectEmit ayuda a mostrar los eventos que se esperan
            // en este caso se espera que se emita una variable
            // y como no hay datos no indexados se ponen false al final
            // si hubiera datos no indexados se pondrían true
            vm.expectEmit(true, false, false, false, address(raffle));

            emit EnetedRaffle(PLAYER1);

            raffle.enterRaffle{value: ticketPrice}();
            
        vm.stopPrank();
    }

    modifier raffleEnterAndTimePassed() {
        vm.startPrank(PLAYER1);
            raffle.enterRaffle{value: ticketPrice}();
        vm.stopPrank();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function  testCantEnterWhenRaffleIsCalculated() public raffleEnterAndTimePassed {
            raffle.performUpkeep("");
            vm.expectRevert(Raffle.Raffle__raffleClosed.selector);
        vm.startPrank(PLAYER1);
            raffle.enterRaffle{value: ticketPrice}();
        vm.stopPrank();
    }

    //////////////////
    // Check Upkeep //
    //////////////////
    function testCheckUpKeepReturnsFalseIfHasNoBalance() public {
        // 1. Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // 2. Act
        (bool upKeepNeeded,) = raffle.checkUpkeep("");

        // 3. Assert
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfRaffleNotOpen() public raffleEnterAndTimePassed {
        // 1. Arrange
        raffle.performUpkeep("");
        // 2. Act
        (bool upKeepNeeded,) = raffle.checkUpkeep("");
        // 3. Assert
        assert(upKeepNeeded == false);
    }
    
    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        // 1. Arrange
        vm.startPrank(PLAYER1);
            raffle.enterRaffle{value: ticketPrice}();
            vm.warp(block.timestamp + interval - 1);
        vm.stopPrank();
        // 2. Act
        (bool upKeepNeeded,) = raffle.checkUpkeep("");
        // 3. Assert
        assert(upKeepNeeded == false);
    }

    function testCheckUpkeepReturnsTrueWhenParametersGood() public raffleEnterAndTimePassed {
        // Arrange
        

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(upkeepNeeded);
    }

    ////////////////////
    // Perform Upkeep //
    ////////////////////

    function testPerformUpKeepCanOnlyRunIfUpKeepIsTrue() public raffleEnterAndTimePassed {
        raffle.performUpkeep("");
    }

    function testPerformUpKeepRevertIfCheckUpKeepIsFalse() public {
        uint256 aux_currentBalance = 0;
        uint256 aux_currentPlayers = 0;
        uint256 aux_currentState = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                aux_currentBalance,
                aux_currentPlayers,
                aux_currentState
            )
        );
        raffle.performUpkeep("");
        
    }

    function testPerformUpKeepUpdatesRaffleStateAndEmitsRequestId() public raffleEnterAndTimePassed {
        vm.recordLogs(); //guarda todos los logs que se emitan los cules se pueden ver con getRecordedLogs()
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs(); // aqui se obtienen los logs registrados
        // usamos la libreria Vm para obtener los datos de los logs

        /*
        Si vemos el contrato Raffle.sol vemos cuando llamamos a performUpkeep
        se realizan 2 eventosen este orden
        1) dentro de la funcion VRFCoordinatorV2Mock.requestRandomWords
        2) otro en la funcion que llamamos 
        por lo tanto entries[0] es el primer evento y entries[1] es el segundo
        topics[0] es el topic del evento y topics[1] es el topic del requestId
        */
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState aux_raffleState = raffle.getRaffleState();

        assert (uint256(requestId) > 0);
        assert (uint256(aux_raffleState) == 1);

    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Fuzzing Test mas info en https://es.wikipedia.org/wiki/Fuzzing                                              //
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /////////////////////////
    // fulfillsRandomWords //
    /////////////////////////


    // cuando agregamos a la funcion en test alguna variable lo que hara foundry es que 
    // hara un fuzzing de la funcion y probara con diferentes valores de la variable
    function testFulfillRandomWordsCanOnlyBeCallAfterPerformUpKeep(
        uint256 randomRequestId
    ) public raffleEnterAndTimePassed skipFork {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testFulfillRandomWordsPickAwinnerResetsAndSendMoney(

    ) public raffleEnterAndTimePassed skipFork {
        uint256 a_additionalEntrace = 5;
        uint256 a_startingIndex = 1;
        for (uint256 i = a_startingIndex; i < a_additionalEntrace + a_startingIndex; i++) {
            address a_player = address(uint160(i));
            hoax(a_player, STARTING_BALANCE); // le damos dinero y tomamos el rol
            raffle.enterRaffle{value: ticketPrice}();
        }

        uint256 prize = ticketPrice * (a_additionalEntrace + 1);

        vm.recordLogs(); //guarda todos los logs que se emitan los cules se pueden ver con getRecordedLogs()
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs(); // aqui se obtienen los logs registrados
        bytes32 requestId = entries[1].topics[1];

        uint256 a_previousTimeStamp = raffle.getLastTimeStamp();

        //finjimos que somos chainlink y llamamos a la funcion
        VRFCoordinatorV2Mock(vrfCordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        /*
        assert(uint256(raffle.getRaffleState()) == 0);
        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getTotalPlayers() == 0);
        assert(a_previousTimeStamp < raffle.getLastTimeStamp());
        */
        assert(raffle.getRecentWinner().balance == (STARTING_BALANCE + prize - ticketPrice));
    }

}