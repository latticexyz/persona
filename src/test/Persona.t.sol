// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {BaseTest, console} from "./base/BaseTest.sol";

contract PersonaTest is BaseTest {
    function setUp() public {}

    function testExample() public {
        console.log("Hello world!");
        assertTrue(true);
    }
}
