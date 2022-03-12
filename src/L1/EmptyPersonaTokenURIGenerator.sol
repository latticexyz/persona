// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface PersonaTokenURIGenerator {
    function generateTokenURI(uint256 personaId, address owner) external view returns (string memory);
}

contract EmptyPersonaTokenURIGenerator is PersonaTokenURIGenerator {
    function generateTokenURI(uint256 personaId, address owner) external view returns (string memory) {
        return "";
    }
}
