// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import { Test, console } from "forge-std/Test.sol";
import { NoggleNFT } from "../../src/NoggleNFT.sol";
import { DeployNoggleNFT } from "../../script/DeployNoggleNFT.s.sol";

contract NogglesNFTIntegrationTest is Test {
    NoggleNFT noggleNFT;
    DeployNoggleNFT deployer;

    address public USER01 = makeAddr("user01");
    function setUp() public {
        deployer = new DeployNoggleNFT();
        noggleNFT = deployer.run();
    }
    function testViewTokenURIIntegration() public {
        vm.startPrank(USER01);
            noggleNFT.mintNFT();
            console.log(noggleNFT.tokenURI(0));
        vm.stopPrank();
    }

    function testFlipTokenToPurple() public {
        vm.startPrank(USER01);
            noggleNFT.mintNFT();
            console.log("----==| TokenURI antes de cambiar color |==----");
            console.log(noggleNFT.tokenURI(0));
            console.log("-------------------------------------------------");
            noggleNFT.changeColor(0);
            console.log("----==| TokenURI despues de cambiar color |==----");
            console.log(noggleNFT.tokenURI(0));
            console.log("-------------------------------------------------");
        vm.stopPrank();
    }
}