// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Base64} from "base64/base64.sol";
import {BaseRelayRecipient} from "gsn/BaseRelayRecipient.sol";

interface L2CrossDomainMessenger {
    function xDomainMessageSender() external view returns (address);
}

contract PersonaMirror is BaseRelayRecipient {
    event BridgeNuke(uint256 indexed personaId, uint256 nonce);
    event BridgeChangeOwner(uint256 indexed personaId, address indexed from, address indexed to, uint256 nonce);
    event Impersonate(uint256 indexed personaId, address indexed user, address indexed consumer);
    event Deimpersonate(uint256 indexed personaId, address indexed user, address indexed consumer);
    event Authorize(uint256 indexed personaId, address indexed user, address indexed consumer, bytes4[] fnSignatures);
    event Deauthorize(uint256 indexed personaId, address indexed user, address indexed consumer);

    L2CrossDomainMessenger public immutable ovmL2CrossDomainMessenger;
    address public immutable personaL1;

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

    // @dev Data in this struct is "grandfathered"
    // when nonce is incremented. This can either happen
    // through bridgeNuke() or bridgeChangeOwner()
    struct PersonaTransientData {
        // user => consumer => authorization
        mapping(address => mapping(address => PersonaAuthorization)) authorizations;
    }

    // persona ID => persona nonce
    mapping(uint256 => uint256) internal _nonce;

    // persona ID => persona nonce => persona data
    mapping(uint256 => mapping(uint256 => PersonaTransientData)) internal _personaTransientData;

    // persona ID => owner
    mapping(uint256 => address) public ownerOf;

    // user address => consumer contract => active persona
    mapping(address => mapping(address => ActivePersona)) public activePersona;

    constructor(address personaL1Addr, address ovmL2CrossDomainMessengerAddr) {
        personaOwner = msg.sender;
        personaL1 = personaL1Addr;
        ovmL2CrossDomainMessenger = L2CrossDomainMessenger(ovmL2CrossDomainMessengerAddr);
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
                            GSN SUPPORT
    //////////////////////////////////////////////////////////////*/

    function versionRecipient() public pure override returns (string memory) {
        return "0.0.1";
    }

    /*///////////////////////////////////////////////////////////////
                                VIEW
    //////////////////////////////////////////////////////////////*/

    function _getPersonaTransientData(uint256 personaId) internal view returns (PersonaTransientData storage) {
        return _personaTransientData[personaId][_nonce[personaId]];
    }

    function _getAuthorization(
        uint256 personaId,
        address user,
        address consumer
    ) internal view returns (PersonaAuthorization storage) {
        return _getPersonaTransientData(personaId).authorizations[user][consumer];
    }

    function _getPermission(
        uint256 personaId,
        address consumer,
        address user
    ) internal view returns (PersonaPermission) {
        PersonaAuthorization storage auth = _getAuthorization(personaId, user, consumer);
        if (auth.isAuthorized && auth.authorizedFns.length != 0) {
            return PersonaPermission.FUNCTION_SPECIFIC;
        } else if (auth.isAuthorized) {
            return PersonaPermission.CONSUMER_SPECIFIC;
        } else {
            return PersonaPermission.DENY;
        }
    }

    function getActivePersona(address user, address consumer) public view returns (uint256 personaId) {
        // if nonce of active person matches current nonce, return persona id
        // otherwise, then impersonation has expired -> return 0
        return
            activePersona[user][consumer].nonce == _nonce[activePersona[user][consumer].personaId]
                ? activePersona[user][consumer].personaId
                : 0;
    }

    function isAuthorized(
        uint256 personaId,
        address user,
        address consumer,
        bytes4 fnSignature
    ) public view returns (bool) {
        if (user == ownerOf[personaId]) {
            return true;
        } else if (_getPermission(personaId, consumer, user) == PersonaPermission.CONSUMER_SPECIFIC) {
            return true;
        } else if (_getPermission(personaId, consumer, user) == PersonaPermission.FUNCTION_SPECIFIC) {
            bytes4[] memory fns = _getAuthorization(personaId, user, consumer).authorizedFns;
            for (uint256 i = 0; i < fns.length; i++) {
                if (fns[i] == fnSignature) return true;
            }
        }

        return false;
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
            _msgSender() == ownerOf[personaId] ||
                _getPermission(personaId, consumer, _msgSender()) != PersonaPermission.DENY,
            "NOT_AUTHORIZED"
        );
        activePersona[_msgSender()][consumer] = ActivePersona(_nonce[personaId], personaId);

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
        _getPersonaTransientData(personaId).authorizations[user][consumer] = PersonaAuthorization(true, fnSignatures);

        emit Authorize(personaId, user, consumer, fnSignatures);
    }

    function deauthorize(
        uint256 personaId,
        address user,
        address consumer
    ) public onlyPersonaOwner(personaId) {
        delete _getPersonaTransientData(personaId).authorizations[user][consumer];

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
        _nonce[personaId] += 1;

        emit BridgeNuke(personaId, _nonce[personaId]);
    }

    function bridgeChangeOwner(address to, uint256 personaId) public onlyL1Persona {
        address from = ownerOf[personaId];
        ownerOf[personaId] = to;
        _nonce[personaId] += 1;

        emit BridgeChangeOwner(personaId, from, to, _nonce[personaId]);
    }
}
