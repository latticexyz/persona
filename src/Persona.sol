// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {LibCustomArt} from "./libraries/LibCustomArt.sol";
import {Base64} from "base64/base64.sol";
import {LibHelpers} from "./libraries/LibHelpers.sol";

contract Persona is ERC721 {
    uint256 currentTokenId;

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

    // user address => consumer contract => active persona
    mapping(address => mapping(address => ActivePersona)) public activePersona;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        currentTokenId = 1;
    }

    /*///////////////////////////////////////////////////////////////
                                VIEW
    //////////////////////////////////////////////////////////////*/

    function getActivePersona(address user, address consumer) public view returns (uint256 personaId) {
        // if nonce of active person matches current nonce, return persona id
        // otherwise, then impersonation have expires -> return 0
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

    function _personaData(uint256 personaId) internal view returns (PersonaData storage) {
        return personaData[personaId][nonce[personaId]];
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

    /*///////////////////////////////////////////////////////////////
                                MUTATION
    //////////////////////////////////////////////////////////////*/

    function impersonate(uint256 personaId, address consumer) public {
        require(isAuthorized(personaId, msg.sender, consumer, bytes4(0)), "NOT_AUTHORIZED");
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
    ) public {
        _personaData(personaId).permissions[user] = fnSignatures.length == 0
            ? PersonaPermission.CONSUMER_SPECIFIC
            : PersonaPermission.FUNCTION_SPECIFIC;
        _personaData(personaId).authorizations[user][consumer] = PersonaAuthorization(true, fnSignatures);
    }

    // // TODO
    // function authorizeWithHook(
    //     uint256 personaId,
    //     address user,
    //     address hookContract,
    //     bytes4 callbackFunction
    // ) public {}

    function deauthorize(
        uint256 personaId,
        address user,
        address consumer
    ) public {
        _personaData(personaId).permissions[user] = PersonaPermission.DENY;
        delete _personaData(personaId).authorizations[user][consumer];
        delete activePersona[user][consumer];
    }

    function nuke(uint256 personaId) public {
        require(ownerOf[personaId] == msg.sender, "NOT_PERSONA_OWNER");
        nonce[personaId] += 1;
    }

    /*///////////////////////////////////////////////////////////////
                            NFT Functions
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 id) public view override returns (string memory) {
        return "";
    }

    function mint() public {
        _safeMint(msg.sender, currentTokenId);
        currentTokenId += 1;
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        super.transferFrom(from, to, id);
        nonce[id] = nonce[id] + 1;
    }
}
