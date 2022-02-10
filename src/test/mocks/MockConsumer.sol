// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {Persona} from "../../Persona.sol";
import {console} from "../utils/console.sol";

contract MockConsumer {
    Persona persona; 

    constructor(address personaAddress) {
        persona = Persona(personaAddress);
    }

    modifier onlyAuthorized() {
        uint256 personaId = persona.getActivePersona(msg.sender, address(this));
        require(persona.isAuthorized(personaId, msg.sender, address(this), msg.sig));
        _;
    }

    function foo() public onlyAuthorized() view returns (uint256) {
        uint256 personaId = persona.getActivePersona(msg.sender, address(this));
        return personaId;
    }
}
