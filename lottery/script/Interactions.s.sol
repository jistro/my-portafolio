// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import { Script, console } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script{

    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (
            /*uint256 ticketPrice*/, 
            /*uint256 interval*/,
            address vrfCordinator, 
            /*bytes32 KeyHash*/,
            /*uint64 subscriptionId*/,
            /*uint32 callbackGasLimit*/,
            /*address link*/,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCordinator, deployerKey);
    }

    function createSubscription(
        address _vrfCordinator,
        uint256 _deployerKey
    ) public returns (uint64) {
        console.log("Creating subscription on Chain ID: ", block.chainid);
        vm.startBroadcast(_deployerKey); // usando la llave privada del deployer
            uint64 subID = VRFCoordinatorV2Mock(_vrfCordinator).createSubscription();
        vm.stopBroadcast();
        console.log("----------------------------------------------------");
        console.log("Subscription ID: ", subID);
        console.log("----------------------------------------------------");
        console.log("  Update the subscription ID in HelperConfig.s.sol  ");
        console.log("----------------------------------------------------");
        return subID;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            /*uint256 ticketPrice*/, 
            /*uint256 interval*/,
            address vrfCordinator, 
            /*bytes32 KeyHash*/,
            uint64 subscriptionId,
            /*uint32 callbackGasLimit*/,
            address link,
            /*uint256 deployerKey*/
        ) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCordinator, subscriptionId, link);
    }

    function fundSubscription(address _vrfCordinator, uint64 _subscriptionId, address _link) public {
        console.log("Funding subscription on Chain ID: ", block.chainid);
        console.log("Using vrfCordinator: ", _vrfCordinator);
        console.log("Using subscriptionId: ", _subscriptionId);
        console.log("Using link: ", _link);

        if (block.chainid == 31337){
            vm.startBroadcast();
                VRFCoordinatorV2Mock(_vrfCordinator).fundSubscription(_subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
                LinkToken(_link).transferAndCall(_vrfCordinator, FUND_AMOUNT, abi.encode(_subscriptionId));
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {

    function addConsumer(
        address _raffle, 
        address vrfCordinator, 
        uint64 subscriptionId,
        uint256 deployerKey

    ) public {
        console.log("Adding consumer on Chain ID: ", block.chainid);
        console.log("Using raffle: ", _raffle);
        console.log("Using vrfCordinator: ", vrfCordinator);
        console.log("Using subscriptionId: ", subscriptionId);
        vm.startBroadcast(deployerKey); // usando la llave privada del deployer
            VRFCoordinatorV2Mock(vrfCordinator).addConsumer(subscriptionId, _raffle);
        vm.stopBroadcast();
    }
    function addConsumerUsingConfig(address _raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (
            /*uint256 ticketPrice*/, 
            /*uint256 interval*/,
            address vrfCordinator, 
            /*bytes32 KeyHash*/,
            uint64 subscriptionId,
            /*uint32 callbackGasLimit*/,
            /*address link*/,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();
        addConsumer(_raffle, vrfCordinator, subscriptionId, deployerKey);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(raffle);
    }
}