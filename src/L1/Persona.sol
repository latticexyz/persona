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
    L1CrossDomainMessenger immutable ovmL1CrossDomainMessenger;

    address public owner;
    address personaMirrorL2;
    uint256 currentPersonaId;

    // address => can mint
    mapping(address => bool) public isMinter;

    modifier onlyMinter() {
        require(isMinter[msg.sender], "ONLY_MINTER");
        _;
    }

    modifier onlyContractOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    modifier onlyPersonaOwner(uint256 personaId) {
        require(msg.sender == ownerOf[personaId], "ONLY_PERSONA_OWNER");
        _;
    }

    constructor(string memory name, string memory symbol, address ovmL1CrossDomainMessengerAddr) ERC721(name, symbol) {
        owner = msg.sender;
        ovmL1CrossDomainMessenger = L1CrossDomainMessenger(ovmL1CrossDomainMessengerAddr);
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


    function _sendChangeOwner(address recipient, uint256 id) internal {
        require(personaMirrorL2 != address(0), "ZERO_ADDR");
        ovmL1CrossDomainMessenger.sendMessage(
            personaMirrorL2,
            abi.encodeWithSignature(
                "bridgeChangeOwner(address, uint256)",
                recipient,
                id
            ),
            1000000 // use whatever gas limit you want
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
            1000000 // use whatever gas limit you want
        );
    }

    function mint(address to) public onlyMinter {
        _mint(to, currentPersonaId);
        _sendChangeOwner(to, currentPersonaId);
        currentPersonaId++;
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
