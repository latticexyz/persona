// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Base64} from "base64/base64.sol";
import {BaseRelayRecipient} from "gsn/BaseRelayRecipient.sol";

interface L2CrossDomainMessenger {
    function xDomainMessageSender() external view returns (address);
}

contract PersonaMirror is BaseRelayRecipient {
    event BridgeNuke(uint256 personaId, uint256 nonce);
    event BridgeChangeOwner(uint256 personaId, address from, address to, uint256 nonce);
    event Impersonate(uint256 personaId, address user, address consumer);
    event Deimpersonate(uint256 personaId, address user, address consumer);
    event Authorize(uint256 personaId, address user, address consumer, bytes4[] fnSignatures);
    event Deauthorize(uint256 personaId, address user, address consumer);

    L2CrossDomainMessenger immutable ovmL2CrossDomainMessenger;
    address immutable personaL1;

    address public personaOwner;

    enum PersonaPermission {
        DENY,
        CONSUMER_SPECIFIC,
        FUNCTION_SPECIFIC
    }

    struct PersonaAuthorization {
        bool isAuthorized;
        bytes4[] authorizedFns;
    }

    struct ActivePersona {
        uint256 nonce;
        uint256 personaId;
    }

    struct PersonaData {
        // user => permissions
        mapping(address => PersonaPermission) permissions;
        // user => consumer => authorization
        mapping(address => mapping(address => PersonaAuthorization)) authorizations;
    }

    // persona ID => persona nonce
    mapping(uint256 => uint256) internal nonce;

    // persona ID => persona nonce => persona data
    mapping(uint256 => mapping(uint256 => PersonaData)) internal personaData;

    // persona id => owner
    mapping(uint256 => address) public ownerOf;

    // user address => consumer contract => active persona
    mapping(address => mapping(address => ActivePersona)) public activePersona;

    constructor(address personaL1ContractAddr, address ovmL2CrossDomainMessengerAddr) {
        personaOwner = msg.sender;
        personaL1 = personaL1ContractAddr;
        ovmL2CrossDomainMessenger = L2CrossDomainMessenger(ovmL2CrossDomainMessengerAddr);
    }

    /*///////////////////////////////////////////////////////////////
                            GSN SUPPORT
    //////////////////////////////////////////////////////////////*/

    function versionRecipient() public pure override returns (string memory) {
        return "0.0.1";
    }

    /*///////////////////////////////////////////////////////////////
                                VIEW
    //////////////////////////////////////////////////////////////*/

    function getActivePersona(address user, address consumer) public view returns (uint256 personaId) {
        // if nonce of active person matches current nonce, return persona id
        // otherwise, then impersonation has expired -> return 0
        return
            activePersona[user][consumer].nonce == nonce[activePersona[user][consumer].personaId]
                ? activePersona[user][consumer].personaId
                : 0;
    }

    function getPermission(uint256 personaId, address user) public view returns (PersonaPermission) {
        return _personaData(personaId).permissions[user];
    }

    function getAuthorization(
        uint256 personaId,
        address user,
        address consumer
    ) public view returns (PersonaAuthorization memory) {
        return _personaData(personaId).authorizations[user][consumer];
    }

    function isAuthorized(
        uint256 personaId,
        address user,
        address consumer,
        bytes4 fnSignature
    ) public view returns (bool) {
        if (user == ownerOf[personaId]) {
            return true;
        } else if (getPermission(personaId, user) == PersonaPermission.DENY) {
            return false;
        } else if (getPermission(personaId, user) == PersonaPermission.CONSUMER_SPECIFIC) {
            return getAuthorization(personaId, user, consumer).isAuthorized;
        } else if (getPermission(personaId, user) == PersonaPermission.FUNCTION_SPECIFIC) {
            bytes4[] memory fns = getAuthorization(personaId, user, consumer).authorizedFns;
            for (uint256 i = 0; i < fns.length; i++) {
                if (fns[i] == fnSignature) {
                    return true;
                }
            }
        }
        return false;
    }

    function _personaData(uint256 personaId) internal view returns (PersonaData storage) {
        return personaData[personaId][nonce[personaId]];
    }

    /*///////////////////////////////////////////////////////////////
                            ACCESS CONTROL
    //////////////////////////////////////////////////////////////*/

    modifier onlyContractOwner() {
        require(_msgSender() == personaOwner, "ONLY_CONTRACT_OWNER");
        _;
    }

    modifier onlyPersonaOwner(uint256 personaId) {
        require(_msgSender() == ownerOf[personaId], "ONLY_PERSONA_OWNER");
        _;
    }

    modifier onlyL1Persona() {
        require(
            // no need for GSN's _msgSender here as this will come from the cross domain contract
            msg.sender == address(ovmL2CrossDomainMessenger) &&
                ovmL2CrossDomainMessenger.xDomainMessageSender() == personaL1,
            "ONLY_L1_PERSONA"
        );
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                ADMIN
    //////////////////////////////////////////////////////////////*/

    function setTrustedForwarder(address trustedForwarderAddr) public onlyContractOwner {
        _setTrustedForwarder(trustedForwarderAddr);
    }

    function setOwner(address newContractOwner) public onlyContractOwner {
        require(newContractOwner != address(0), "ZERO_ADDR");
        personaOwner = newContractOwner;
    }

    /*///////////////////////////////////////////////////////////////
                                MUTATION
    //////////////////////////////////////////////////////////////*/

    function impersonate(uint256 personaId, address consumer) public {
        require(
            _msgSender() == ownerOf[personaId] || getPermission(personaId, _msgSender()) != PersonaPermission.DENY,
            "NOT_AUTHORIZED"
        );
        activePersona[_msgSender()][consumer] = ActivePersona(nonce[personaId], personaId);

        emit Impersonate(personaId, _msgSender(), consumer);
    }

    function deimpersonate(address consumer) public {
        require(getActivePersona(_msgSender(), consumer) != 0, "NO_ACTIVE_PERSONA");

        emit Deimpersonate(activePersona[_msgSender()][consumer].personaId, _msgSender(), consumer);

        delete activePersona[_msgSender()][consumer];
    }

    function authorize(
        uint256 personaId,
        address user,
        address consumer,
        bytes4[] memory fnSignatures
    ) public onlyPersonaOwner(personaId) {
        _personaData(personaId).permissions[user] = fnSignatures.length == 0
            ? PersonaPermission.CONSUMER_SPECIFIC
            : PersonaPermission.FUNCTION_SPECIFIC;
        _personaData(personaId).authorizations[user][consumer] = PersonaAuthorization(true, fnSignatures);

        emit Authorize(personaId, user, consumer, fnSignatures);
    }

    function deauthorize(
        uint256 personaId,
        address user,
        address consumer
    ) public onlyPersonaOwner(personaId) {
        _personaData(personaId).permissions[user] = PersonaPermission.DENY;
        delete _personaData(personaId).authorizations[user][consumer];

        // We want to force deimpersonate the user only if they
        // are currently impersonating as `personaId`
        if (activePersona[user][consumer].personaId == personaId) {
            delete activePersona[user][consumer];
        }

        emit Deauthorize(personaId, user, consumer);
    }

    /*///////////////////////////////////////////////////////////////
                            BRIDGING
    //////////////////////////////////////////////////////////////*/

    function bridgeNuke(uint256 personaId) public onlyL1Persona {
        nonce[personaId] += 1;

        emit BridgeNuke(personaId, nonce[personaId]);
    }

    function bridgeChangeOwner(address to, uint256 personaId) public onlyL1Persona {
        address from = ownerOf[personaId];
        ownerOf[personaId] = to;
        nonce[personaId] += 1;

        emit BridgeChangeOwner(personaId, from, to, nonce[personaId]);
    }
}
