// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";

contract NoggleNFT is ERC721 {
    error NoggleNFT__tokenURI__InvalidTokenId(uint256 tokenId);
    error NoggleNFT__changeColor__NotOwner(uint256 tokenId);

    uint256 private s_tokenCounter;
    string private s_originalNoggleImageURI;
    string private s_purpleNoggleImageURI;

    enum color {
        original, 
        purple
    }

    mapping (uint256 => color) private s_tokenIdToColor;
    constructor(
        string memory originalNoggleImageURI,
        string memory purpleNoggleImageURI
    ) 
    ERC721("Noggle", "NC") {
        s_tokenCounter = 0;
        s_originalNoggleImageURI = originalNoggleImageURI;
        s_purpleNoggleImageURI = purpleNoggleImageURI;
    }

    function mintNFT() public {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter++;
        s_tokenIdToColor[s_tokenCounter] = color.original;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function changeColor(uint256 tokenId) public {
        if (!(_isApprovedOrOwner(msg.sender, tokenId))){
            revert NoggleNFT__changeColor__NotOwner(tokenId);
        }
        if (s_tokenIdToColor[tokenId] == color.original){
            s_tokenIdToColor[tokenId] = color.purple;
        } else {
            s_tokenIdToColor[tokenId] = color.original;
        }
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns(string memory){

        string memory _imageURI = "";

        if (s_tokenIdToColor[tokenId] == color.original){
            _imageURI = s_originalNoggleImageURI;
        } else if (s_tokenIdToColor[tokenId] == color.purple){
            _imageURI = s_purpleNoggleImageURI;
        } else {
            revert NoggleNFT__tokenURI__InvalidTokenId(tokenId); 
            
        }
        
        return string(
            abi.encodePacked( _baseURI(),
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name": "', 
                            name(), 
                            '","description": "Just a pair of nouns glasses", "atributes": [{"trait_type": "nounish", "value":100}], "image": "', 
                            _imageURI,
                            '" }'
                        )
                    )
                )
            )
        );

    }
}