// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {Base64} from "base64/base64.sol";
import {LibCustomArt} from "../libraries/LibCustomArt.sol";
import {LibHelpers} from "../libraries/LibHelpers.sol";

interface L2CrossDomainMessenger {
    function xDomainMessageSender() external view returns (address);
}

contract PersonaMirror {
    address immutable personaL1;
    L2CrossDomainMessenger immutable ovmL2CrossDomainMessenger;

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
        personaL1 = personaL1ContractAddr;
        ovmL2CrossDomainMessenger = L2CrossDomainMessenger(ovmL2CrossDomainMessengerAddr);
    }

    /*///////////////////////////////////////////////////////////////
                            ACCESS CONTROL
    //////////////////////////////////////////////////////////////*/

    modifier onlyPersonaOwner(uint256 personaId) {
        require(msg.sender == ownerOf[personaId]);
        _;
    }

    modifier onlyPersonaAuthorized(uint256 personaId, address consumer) {
        require(isAuthorized(personaId, msg.sender, consumer, bytes4(0)));
        _;
    }

    modifier onlyL1Persona() {
        require(
            msg.sender == address(ovmL2CrossDomainMessenger) &&
                ovmL2CrossDomainMessenger.xDomainMessageSender() == personaL1
        );
        _;
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
                                MUTATION
    //////////////////////////////////////////////////////////////*/

    function impersonate(uint256 personaId, address consumer) public {
        require(getPermission(personaId, msg.sender) != PersonaPermission.DENY);
        activePersona[msg.sender][consumer] = ActivePersona(nonce[personaId], personaId);
    }

    function deimpersonate(address consumer) public {
        require(getActivePersona(msg.sender, consumer) != 0, "NO_ACTIVE_PERSONA");
        delete activePersona[msg.sender][consumer];
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
    }

    function deauthorize(
        uint256 personaId,
        address user,
        address consumer
    ) public onlyPersonaOwner(personaId) {
        _personaData(personaId).permissions[user] = PersonaPermission.DENY;
        delete _personaData(personaId).authorizations[user][consumer];
        delete activePersona[user][consumer];
    }

    /*///////////////////////////////////////////////////////////////
                            NFT Functions
    //////////////////////////////////////////////////////////////*/

    function bridgeNuke(uint256 personaId) public onlyL1Persona {
        nonce[personaId] += 1;
    }

    function bridgeMirror(address recipient) public onlyL1Persona returns (uint256 id) {
        require(recipient != address(0), "INVALID_RECIPIENT");
        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        ownerOf[id] = recipient;
    }
}
