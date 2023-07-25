// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Script , console } from "forge-std/Script.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { NoggleNFT } from "../src/NoggleNFT.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";

contract DeployNoggleNFT is Script {
    function run() external returns (NoggleNFT) {
        // lee los archivos svg
        // para poder leer escribir algun archivo debemos darle permisos
        // a nuestro entorno de ejecucion en foundry.toml
        string memory clasicNoggleSVG = vm.readFile("./img/nogglesClasic.svg");
        string memory purpleNoggleSVG = vm.readFile("./img/nogglesPurple.svg");
        vm.startBroadcast();
        console.log("Deploying NoggleNFT...");
            NoggleNFT noggleNFT = new NoggleNFT(
                sgvToImageURI(clasicNoggleSVG),
                sgvToImageURI(purpleNoggleSVG)
            );
        vm.stopBroadcast();
        console.log("----------------------------==Contrato desplegado==----------------------------");
        console.log("Direccion del contrato: ", address(noggleNFT));
        console.log("-------------------------------------------------------------------------------");
        
        return noggleNFT;
    }

    function sgvToImageURI(
        string memory _svg
    ) public pure returns (string memory) {
        string memory baseURI = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(_svg)
                )
            )
        );
        
        return string(
            abi.encodePacked(
                baseURI,
                svgBase64Encoded
            )
        );
    }
}