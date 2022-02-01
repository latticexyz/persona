// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {LibCustomArt} from "./libraries/LibCustomArt.sol";
import {Base64} from 'base64/base64.sol';
import {LibHelpers} from './libraries/LibHelpers.sol';

contract Persona is ERC721 {

    uint256 currentTokenId;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    /*///////////////////////////////////////////////////////////////
                                VIEW
    //////////////////////////////////////////////////////////////*/

    function getPersona(address target) public view returns (uint256 personaId) {}

    function isAuthorized(uint256 personaId, address target) public returns (bool authorized) {}

    /*///////////////////////////////////////////////////////////////
                                MUTATION
    //////////////////////////////////////////////////////////////*/

    function impersonate(uint256 personaId) public {}

    function deimpersonate() public {}

    function authorize(uint256 personaId, address target, address gameContract) public {}

    function authorize(uint256 personaId, address target, address gameContract, bytes4[] memory fnSignatures) public {}

    function authorizeWithHook(uint256 personaId, address target, address hookContract, bytes4 callbackFunction) public {}

    function deauthorize(uint256 personaId, address target) public {}

    /*///////////////////////////////////////////////////////////////
                                ART
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 id)
        public
        view
        override
        returns (string memory)
    {
        address owner = ownerOf[id];
        require(owner != address(0), "Token does not exist.");

        string memory image = LibCustomArt.artForPersona(getPersona(owner), owner); 

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                'Sample description for Persona NFT',
                                '", "image": "',
                                'data:image/svg+xml;base64,',
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}