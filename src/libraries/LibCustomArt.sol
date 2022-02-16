// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Persona} from "../L1/Persona.sol";

library LibCustomArt {
    // Returns the 5 gradient hex colors for the given personaId.
    function gradientForAddress(uint256 personaId) internal pure returns (bytes[4] memory) {}

    /// Returns the heights of the 10 bars in the barcode for the given personaId.
    function barsForAddress(uint256 personaId) internal pure returns (uint8[32] memory) {}
}
