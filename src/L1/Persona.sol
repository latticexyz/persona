// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {ERC721} from "solmate/tokens/ERC721.sol";

interface L1CrossDomainMessenger {
    function sendMessage(
        address _target,
        bytes memory _message,
        uint32 _gasLimit
    ) external;
}


contract Persona is ERC721 {

    // address => can mint
    mapping(address => bool) public isMinter;

    address public owner;

    L1CrossDomainMessenger immutable ovmL1CrossDomainMessenger;
    address personaMirrorL2;

    constructor(string memory name, string memory symbol, address ovmL1CrossDomainMessengerAddr) ERC721(name, symbol) {
        ovmL1CrossDomainMessenger = L1CrossDomainMessenger(ovmL1CrossDomainMessengerAddr);
    }

    modifier onlyMinter() {
        require(isMinter[msg.sender]);
        _;
    }

    modifier onlyContractOwner() {
        require(msg.sender == owner);
        _;
    }

    function setMinter(address minter, bool allowMint) public onlyContractOwner {
        isMinter[minter] = allowMint;
    }

    function setOwner(address newContractOwner) public onlyContractOwner {
        require(newContractOwner != address(0), "ZERO_ADDR");
        owner = newContractOwner;
    } 
    
    function setPersonaMirrorL2(address personaMirrorAddr) public onlyContractOwner {
        require(personaMirrorAddr != address(0), "ZERO_ADDR");
        personaMirrorL2 = personaMirrorAddr;
    } 

    modifier onlyPersonaOwner(uint256 personaId) {
        require(msg.sender == ownerOf[personaId]);
        _;
    }

    function _sendChangeOwner(address recipient, uint256 id) internal {
        require(personaMirrorL2 != address(0), "ZERO_ADDR");
        ovmL1CrossDomainMessenger.sendMessage(
            personaMirrorL2,
            abi.encodeWithSignature(
                "bridgeChangeOwner(address, uint256)",
                recipient,
                id
            ),
            60000 // use whatever gas limit you want
        );
    }

    function _sendNuke(uint256 id) internal {
        require(personaMirrorL2 != address(0), "ZERO_ADDR");
        ovmL1CrossDomainMessenger.sendMessage(
            personaMirrorL2,
            abi.encodeWithSignature(
                "bridgeNuke(uint256)",
                id
            ),
            40000 // use whatever gas limit you want
        );
    }

    function mint(address to, uint256 personaId) public onlyMinter {
        _mint(to, personaId);
        _sendChangeOwner(to, personaId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        super.transferFrom(from, to, id);
        _sendChangeOwner(to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        super.safeTransferFrom(from, to, id);
        _sendChangeOwner(to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public override {
        super.safeTransferFrom(from, to, id, data);
        _sendChangeOwner(to, id);
    }

    function nuke(uint256 personaId) public onlyPersonaOwner(personaId) {
        _sendNuke(personaId);
    }

    function tokenURI(uint256 personaId) public view override returns (string memory) {
        return "";
    }
}
