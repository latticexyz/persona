// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {PersonaMirror} from "../../L2/PersonaMirror.sol";
import {console} from "../utils/console.sol";

contract MockConsumer {
    PersonaMirror personaMirror;

    constructor(address personaMirrorAddress) {
        personaMirror = PersonaMirror(personaMirrorAddress);
    }

    modifier onlyAuthorized() {
        uint256 personaId = personaMirror.getActivePersona(msg.sender, address(this));
        require(personaMirror.isAuthorized(personaId, msg.sender, address(this), msg.sig));
        _;
    }

    function foo() public view onlyAuthorized returns (uint256) {
        uint256 personaId = personaMirror.getActivePersona(msg.sender, address(this));
        return personaId;
    }
}
