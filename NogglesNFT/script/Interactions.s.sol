// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Script } from "forge-std/Script.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { BasicNFT } from "../src/BasicNFT.sol";
import { DevOpsTools } from "lib/foundry-devops/src/DevOpsTools.sol";


contract MintBasicNFT is Script {
    string constant DONA_METADATA = "https://ipfs.io/ipfs/QmZjp13pA4kTdjPtksxhF94f22EbAsLyKbi7NaCC4KpJVm";
    function run() external {
        address mostRecentDeployedAddress = DevOpsTools.get_most_recent_deployment(
            "BasicNFT", 
            block.chainid
        );
        mintNFTOnContract(mostRecentDeployedAddress);
    }

    function mintNFTOnContract(address _contract) public {
        vm.startBroadcast();
            BasicNFT(_contract).mintNFT(DONA_METADATA);
        vm.stopBroadcast();
    }
}

