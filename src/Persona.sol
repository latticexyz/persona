// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {NFTSVG} from "./NFTSVG.sol";


/// @title Persona NFT Token
/// @author Scott Sunarto, Lattice
contract Persona is ERC721 {

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    function tokenURI(uint256 id) public view override returns (string memory) {
        string memory cool = "hi";
        return cool;
    }

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

    function deauthorize(uint256 personaId, address target) -> Remove target's authorization to impersonate public {}
}