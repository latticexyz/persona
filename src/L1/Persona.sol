// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {ERC721} from "solmate/tokens/ERC721.sol";

contract Persona is ERC721 {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    }
    function tokenURI(uint256 personaId) public view override returns (string memory) {
        return "";
    }
}
