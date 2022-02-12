// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {PersonaMirror} from "../L2/PersonaMirror.sol";

/// @title PersonaConsumer
/// @notice You can inherit from this contract in order to use the helper
/// functions defined within to interact with Persona.
contract PersonaConsumer {

    /// @notice The PersonaMirror contract that lives on L2.
    PersonaMirror persona;

    /// @dev You must pass address of the L2 PersonaMirror contract
    /// that you want this contract to interact with.
    constructor(address _persona) {
        persona = PersonaMirror(_persona);
    }

    /// @notice Checks if the address calling the function in the consumer contract
    /// is authorized to call that function according to their PersonaAuthorization
    /// @dev Use this modifier on functions that you want to be compatible with Persona.
    modifier onlyAuthorized() {
        PersonaMirror personaMirror = PersonaMirror(persona);
        uint256 personaId = personaMirror.getActivePersona(msg.sender, address(this));
        require(personaMirror.isAuthorized(personaId, msg.sender, address(this), msg.sig));
        _;
    }

    /// @notice Returns the personaId of msg.sender.
    /// @return personaId The personaId associated with the msg.sender address.
    function __msgSender() public view returns (uint256 personaId) {
        personaId = persona.getActivePersona(msg.sender, address(this));
    }
}