// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 ticketPrice; 
        uint256 interval;
        address vrfCordinator; 
        bytes32 KeyHash;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address linkToken;
        uint256 deployerKey;
    }
    
    uint256 public constant DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111){
            activeNetworkConfig = getSepoliaEthConfig();
            console.log("(----------------------)");
            console.log("(-Using Sepolia Config-)");
            console.log("(----------------------)");
        } else if (block.chainid == 43113){
            activeNetworkConfig = getFujiAvaxConfig();
            console.log("[------------------------]");
            console.log("[-Using Fuji Avax Config-]");
            console.log("[------------------------]");
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
            console.log("|----------------------------|");
            console.log("|-Using Anvil (local) Config-|");
            console.log("|----------------------------|");
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            ticketPrice: 0.001 ether,
            interval: 30,
            vrfCordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            KeyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 3773, //Update this
            callbackGasLimit: 500000,
            linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getFujiAvaxConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            ticketPrice: 0.01 ether,
            interval: 30,
            vrfCordinator: 	0x2eD832Ba664535e5886b75D64C46EB9a228C2610,
            KeyHash: 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61,
            subscriptionId: 0, //Update this
            callbackGasLimit: 1500000,
            linkToken: 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilConfig()  public returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCordinator != address(0)){
            return activeNetworkConfig;
        }
        uint96 baseFee = 0.25 ether;
        uint96 gasPriceLink = 1e9; // 1 gwei
        vm.startBroadcast();
            VRFCoordinatorV2Mock vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(
                baseFee,
                gasPriceLink
            );
        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        return NetworkConfig({
            ticketPrice: 0.01 ether,
            interval: 30,
            vrfCordinator: address(vrfCoordinatorV2Mock),
            KeyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0, //Update this
            callbackGasLimit: 1500000,
            linkToken: address(link),
            deployerKey: DEFAULT_ANVIL_KEY
        });
    }
}