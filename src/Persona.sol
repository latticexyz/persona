// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {LibCustomArt} from "./libraries/LibCustomArt.sol";
import {Base64} from 'base64/base64.sol';

contract Persona is ERC721 {

    uint256 currentTokenId;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    /*///////////////////////////////////////////////////////////////
                                VIEW
    //////////////////////////////////////////////////////////////*/

    function getPersona(address target) public returns (uint256 personaId) {}

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

    // Returns the gradient for a given address.
    function gradientForAddress(address user) public pure returns (bytes[5] memory) {
        return LibCustomArt.gradientForAddress(user);
    }

    // Generates the artwork for a given address.
    // Currently the SVG is Zora's Zorb svg as a filler.
    function artForAddress(address user) public view returns (string memory) {
        bytes[5] memory colors = gradientForAddress(user);
        string memory encoded = Base64.encode(
            bytes(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 110 110"><defs>'
                    // new gradient fix – test
                    '<radialGradient id="gzr" gradientTransform="translate(66.4578 24.3575) scale(75.2908)" gradientUnits="userSpaceOnUse" r="1" cx="0" cy="0%">'
                    // '<radialGradient fx="66.46%" fy="24.36%" id="grad">'
                    '<stop offset="15.62%" stop-color="',
                    colors[0],
                    '" /><stop offset="39.58%" stop-color="',
                    colors[1],
                    '" /><stop offset="72.92%" stop-color="',
                    colors[2],
                    '" /><stop offset="90.63%" stop-color="',
                    colors[3],
                    '" /><stop offset="100%" stop-color="',
                    colors[4],
                    '" /></radialGradient></defs><g transform="translate(5,5)">'
                    '<path d="M100 50C100 22.3858 77.6142 0 50 0C22.3858 0 0 22.3858 0 50C0 77.6142 22.3858 100 50 100C77.6142 100 100 77.6142 100 50Z" fill="url(#gzr)" /><path stroke="rgba(0,0,0,0.075)" fill="transparent" stroke-width="1" d="M50,0.5c27.3,0,49.5,22.2,49.5,49.5S77.3,99.5,50,99.5S0.5,77.3,0.5,50S22.7,0.5,50,0.5z" />'
                    "</g></svg>"
                )
            )
        );
        return string(abi.encodePacked("data:image/svg+xml;base64,", encoded));
    }

    function tokenURI(uint256 id)
        public
        view
        override
        returns (string memory)
    {
        require(ownerOf[id] != address(0), "Token does not exist.");

        string memory image = artForAddress(ownerOf[id]); 

        return
            string(
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
            );
    }
}