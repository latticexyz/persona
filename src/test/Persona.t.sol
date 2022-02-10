// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {BaseTest, console} from "./base/BaseTest.sol";

import {MockConsumer} from "./mocks/MockConsumer.sol";
import {Persona} from "../Persona.sol";

contract PersonaTest is BaseTest {
    MockConsumer consumer;
    Persona persona;

    enum PersonaPermission {
        DENY,
        CONSUMER_SPECIFIC,
        FUNCTION_SPECIFIC
    }

    /// Mock Addresses \\\
    address deployer = address(1);
    address minter = address(2);
    address personaOwner = address(3);
    address alice = address(5);
    address bob = address(6);

    function setUp() public {
        vm.startPrank(deployer);
        persona = new Persona("Lattice Persona", "LTX-PERSONA");
        consumer = new MockConsumer(address(persona));
        vm.stopPrank();
    }

    /// Access Control \\\
    function testDeployOwner() public {
        assertEq(persona.owner(), deployer);
    }

    function testSetOwner() public {
        vm.startPrank(deployer);
        persona.setOwner(alice);

        assertEq(persona.owner(), alice);
    }

    function testFailSetOwnerZeroAddr() public {
        vm.startPrank(deployer);
        persona.setOwner(address(0));
    }

    function testSetMinterTrue() public {
        vm.startPrank(deployer);
        persona.setMinter(minter, true);

        assertTrue(persona.isMinter(minter));
    }

    function testSetMinterFalse() public {
        vm.startPrank(deployer);
        persona.setMinter(minter, false);

        assertTrue(!persona.isMinter(minter));
    }

    /// Minting \\\
    function _mintTo(address recipient) internal returns (uint256 id) {
        vm.prank(deployer);
        persona.setMinter(minter, true);

        vm.prank(minter);
        id = persona.mint(recipient);
    }

    function testMint() public {
        _mintTo(personaOwner);

        assertEq(persona.balanceOf(personaOwner), 1);
        assertEq(persona.ownerOf(1), personaOwner);
    }

    function testFailMintAsNonMinter() public {
        vm.prank(deployer);
        persona.setMinter(minter, true);

        vm.prank(alice);
        persona.mint(personaOwner);
    }

    /// Impersonation \\\
    function testImpersonationAsOwner() public {
        uint256 id = _mintTo(personaOwner);

        vm.startPrank(personaOwner);
        persona.impersonate(id, address(consumer));
        vm.stopPrank();

        assertTrue(persona.getActivePersona(personaOwner, address(consumer)) == id);
    }

    function testImpersonationAsConsumerSpecific() public {
        uint256 id = _mintTo(personaOwner);
        _authorizeConsumerSpecific(id, alice, address(consumer));

        vm.startPrank(alice);
        persona.impersonate(id, address(consumer));
        assertTrue(persona.getActivePersona(address(alice), address(consumer)) == id);
        vm.stopPrank();
    }

    function testImpersonationAsFunctionSpecific() public {
        uint256 id = _mintTo(personaOwner);
        bytes4[] memory fnSignatures = new bytes4[](1);
        bytes4 selector = consumer.foo.selector;
        fnSignatures[0] = selector;
        _authorizeFunctionSpecific(id, alice, address(consumer), fnSignatures);

        vm.startPrank(alice);
        persona.impersonate(id, address(consumer));
        assertTrue(persona.getActivePersona(address(alice), address(consumer)) == id);
        vm.stopPrank();
    }

    function testFailImpersonationWithoutPermissions() public {
        uint256 id = _mintTo(personaOwner);
        persona.impersonate(id, address(consumer));
    }

    /// Deimpersonation \\\
    function testDeimpersonation() public {
        uint256 id = _mintTo(personaOwner);
        _authorizeConsumerSpecific(id, alice, address(consumer));

        vm.startPrank(alice);
        persona.impersonate(id, address(consumer));
        assertTrue(persona.getActivePersona(address(alice), address(consumer)) == id);
        persona.deimpersonate(address(consumer));
        assertTrue(persona.getActivePersona(address(alice), address(consumer)) == uint256(0));
        vm.stopPrank();
    }

    /// Authorization \\\
    function _authorizeConsumerSpecific(
        uint256 id,
        address user,
        address targetConsumer
    ) internal {
        vm.startPrank(personaOwner);
        persona.authorize(id, user, targetConsumer, new bytes4[](0));
        vm.stopPrank();
    }

    function _authorizeFunctionSpecific(
        uint256 id,
        address user,
        address targetConsumer,
        bytes4[] memory fnSignatures
    ) internal {
        vm.startPrank(personaOwner);
        persona.authorize(id, user, targetConsumer, fnSignatures);
        vm.stopPrank();
    }

    function testAuthorizeConsumerSpecific() public {
        uint256 id = _mintTo(personaOwner);
        _authorizeConsumerSpecific(id, alice, address(consumer));

        assertEq(uint256(persona.getPermission(id, alice)), uint256(PersonaPermission.CONSUMER_SPECIFIC));

        // Test that alice can now call consumer's foo() function
        vm.startPrank(alice);
        persona.impersonate(id, address(consumer));
        uint256 fooResult = consumer.foo();
        assertEq(fooResult, id);
        vm.stopPrank();
    }

    function testAuthorizeFunctionSpecific() public {
        uint256 id = _mintTo(personaOwner);
        bytes4[] memory fnSignatures = new bytes4[](1);
        bytes4 selector = consumer.foo.selector;
        fnSignatures[0] = selector;
        _authorizeFunctionSpecific(id, alice, address(consumer), fnSignatures);

        // Test that persona contract stores permissions correctly
        assertEq(uint256(persona.getPermission(id, alice)), uint256(PersonaPermission.FUNCTION_SPECIFIC));

        // Test that alice can now call consumer's foo() function
        vm.startPrank(alice);
        persona.impersonate(id, address(consumer));
        uint256 fooResult = consumer.foo();
        assertEq(fooResult, id);
        vm.stopPrank();
    }

    /// Deauthorization \\\
    function testPersonaDeauthorizeConsumerSpecific() public {
        uint256 id = _mintTo(personaOwner);
        _authorizeConsumerSpecific(id, alice, address(consumer));

        vm.startPrank(personaOwner);
        persona.deauthorize(id, alice, address(consumer));
        vm.stopPrank();

        assertEq(uint256(persona.getPermission(id, alice)), uint256(PersonaPermission.DENY));
        assertEq(persona.getActivePersona(alice, address(consumer)), uint256(0));
        assertTrue(persona.getAuthorization(id, alice, address(consumer)).isAuthorized == false);
        assertEq(persona.getAuthorization(id, alice, address(consumer)).authorizedFns.length, uint256(0));
    }

    function testFailMockConsumerDeauthorizeConsumerSpecific() public {
        uint256 id = _mintTo(personaOwner);
        _authorizeConsumerSpecific(id, alice, address(consumer));

        vm.startPrank(alice);
        persona.impersonate(id, address(consumer));
        vm.stopPrank();

        vm.startPrank(personaOwner);
        persona.deauthorize(id, alice, address(consumer));
        vm.stopPrank();

        // Test impersonation was removed and alice can no longer call consumer's foo() function
        vm.startPrank(alice);
        consumer.foo();
        vm.stopPrank();
    }

    function testPersonaDeauthorizeFunctionSpecific() public {
        uint256 id = _mintTo(personaOwner);
        bytes4[] memory fnSignatures = new bytes4[](1);
        bytes4 selector = consumer.foo.selector;
        fnSignatures[0] = selector;
        _authorizeFunctionSpecific(id, alice, address(consumer), fnSignatures);

        vm.startPrank(alice);
        persona.impersonate(id, address(consumer));
        vm.stopPrank();

        vm.startPrank(personaOwner);
        persona.deauthorize(id, alice, address(consumer));
        vm.stopPrank();

        assertEq(uint256(persona.getPermission(id, alice)), uint256(PersonaPermission.DENY));
        assertEq(persona.getActivePersona(alice, address(consumer)), uint256(0));
        assertTrue(persona.getAuthorization(id, alice, address(consumer)).isAuthorized == false);
    }

    function testFailMockConsumerDeauthorizeFunctionSpecific() public {
        uint256 id = _mintTo(personaOwner);
        bytes4[] memory fnSignatures = new bytes4[](1);
        bytes4 selector = consumer.foo.selector;
        fnSignatures[0] = selector;
        _authorizeFunctionSpecific(id, alice, address(consumer), fnSignatures);

        vm.startPrank(alice);
        persona.impersonate(id, address(consumer));
        vm.stopPrank();

        vm.startPrank(personaOwner);
        persona.deauthorize(id, alice, address(consumer));
        vm.stopPrank();

        // Test impersonation was removed and alice can no longer call consumer's foo() function
        vm.startPrank(alice);
        consumer.foo();
        vm.stopPrank();
    }

    /// Transfer \\\ 
    function testTransfer() public {
        
    }
}
