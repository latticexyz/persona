// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {Base64} from 'base64/base64.sol';

library LibCustomArt {
    
    // Returns the 5 gradient hex colors for the given address.
    function gradientForAddress(address addr)
        internal
        pure
        returns (bytes[5] memory)
    {
        return [
            bytes("0x00"),
            bytes("0x00"),
            bytes("0x00"),
            bytes("0x00"),
            bytes("0x00")
        ];
    }

    /// Returns the heights of the 10 bars in the barcode for the given address.
    function barsForAddress(address addr) 
        internal
        pure
        returns (uint8[10] memory) 
    {}
}