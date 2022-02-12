// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {BaseRelayRecipient} from "gsn/BaseRelayRecipient.sol";

interface L1CrossDomainMessenger {
    function sendMessage(
        address _target,
        bytes memory _message,
        uint32 _gasLimit
    ) external;
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

contract Persona is ERC721, BaseRelayRecipient {
    L1CrossDomainMessenger immutable ovmL1CrossDomainMessenger;

    address public personaOwner;
    address public personaMirrorL2;
    uint256 public currentPersonaId;

    // address => can mint
    mapping(address => bool) public isMinter;

    constructor(
        string memory name,
        string memory symbol,
        address ovmL1CrossDomainMessengerAddr
    ) ERC721(name, symbol) {
        currentPersonaId = 1;
        personaOwner = msg.sender;
        ovmL1CrossDomainMessenger = L1CrossDomainMessenger(
            ovmL1CrossDomainMessengerAddr
        );
    }

    /*///////////////////////////////////////////////////////////////
                            ACCESS CONTROL
    //////////////////////////////////////////////////////////////*/

    modifier onlyMinter() {
        require(isMinter[_msgSender()], "ONLY_MINTER");
        _;
    }

    modifier onlyContractOwner() {
        require(_msgSender() == personaOwner, "ONLY_OWNER");
        _;
    }

    modifier onlyPersonaOwner(uint256 personaId) {
        require(_msgSender() == ownerOf[personaId], "ONLY_PERSONA_OWNER");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            GSN SUPPORT
    //////////////////////////////////////////////////////////////*/

    function versionRecipient() public pure override returns (string memory) {
        return "0.0.1";
    }

    /*///////////////////////////////////////////////////////////////
                               ADMIN
    //////////////////////////////////////////////////////////////*/

    function setTrustedForwarder(address trustedForwarderAddr)
        public
        onlyContractOwner
    {
        _setTrustedForwarder(trustedForwarderAddr);
    }

    function setMinter(address minter, bool allowMint)
        public
        onlyContractOwner
    {
        isMinter[minter] = allowMint;
    }

    function setOwner(address newContractOwner) public onlyContractOwner {
        require(newContractOwner != address(0), "ZERO_ADDR");
        personaOwner = newContractOwner;
    }

    function setPersonaMirrorL2(address personaMirrorAddr)
        public
        onlyContractOwner
    {
        require(personaMirrorAddr != address(0), "ZERO_ADDR");
        personaMirrorL2 = personaMirrorAddr;
    }

    /*///////////////////////////////////////////////////////////////
                               BRIDGING
    //////////////////////////////////////////////////////////////*/

    function _sendChangeOwner(address recipient, uint256 id) internal {
        require(personaMirrorL2 != address(0), "ZERO_ADDR");
        ovmL1CrossDomainMessenger.sendMessage(
            personaMirrorL2,
            abi.encodeWithSignature(
                "bridgeChangeOwner(address,uint256)",
                recipient,
                id
            ),
            1000000
        );
    }

    function _sendNuke(uint256 id) internal {
        require(personaMirrorL2 != address(0), "ZERO_ADDR");
        ovmL1CrossDomainMessenger.sendMessage(
            personaMirrorL2,
            abi.encodeWithSignature("bridgeNuke(uint256)", id),
            1000000
        );
    }

    /*///////////////////////////////////////////////////////////////
                               PERSONA
    //////////////////////////////////////////////////////////////*/

    function nuke(uint256 personaId) public onlyPersonaOwner(personaId) {
        _sendNuke(personaId);
    }

    /*///////////////////////////////////////////////////////////////
                               ERC721
    //////////////////////////////////////////////////////////////*/

    function mint(address to) public onlyMinter {
        _mint(to, currentPersonaId);
        _sendChangeOwner(to, currentPersonaId);
        currentPersonaId++;
    }

    function approve(address spender, uint256 id) public override {
        address owner = ownerOf[id];

        require(
            _msgSender() == owner || isApprovedForAll[owner][_msgSender()],
            "NOT_AUTHORIZED"
        );

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        isApprovedForAll[_msgSender()][operator] = approved;

        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 id
    ) internal {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            _msgSender() == from ||
                _msgSender() == getApproved[id] ||
                isApprovedForAll[from][_msgSender()],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        _transferFrom(from, to, id);
        _sendChangeOwner(to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        // we call the internal transfer from
        _transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    id,
                    ""
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );

        _sendChangeOwner(to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public override {
        _transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );

        _sendChangeOwner(to, id);
    }

    function tokenURI(uint256 personaId)
        public
        view
        override
        returns (string memory)
    {
        return "";
    }
}
