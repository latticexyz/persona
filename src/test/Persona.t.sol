// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {BaseTest, console} from "./base/BaseTest.sol";

import {MockL2Bridge} from "./mocks/MockL2Bridge.sol";
import {MockConsumer} from "./mocks/MockConsumer.sol";
import {Persona} from "../L1/Persona.sol";
import {PersonaMirror} from "../L2/PersonaMirror.sol";

contract PersonaTest is BaseTest {
    MockL2Bridge bridge;
    Persona persona;
    PersonaMirror personaMirror;
     address deployer = address(1);
     address minter = address(2);
     address personaOwner = address(3);
     address alice = address(5);
     address bob = address(6);
    function setUp() public {
        vm.startPrank(deployer);
        bridge = new MockL2Bridge();
        persona = new Persona("L", "L", address(bridge));
        personaMirror = new PersonaMirror(address(persona), address(bridge));
        persona.setPersonaMirrorL2(address(personaMirror));
        vm.stopPrank();
    }
    // /// Access Control \\\
    function testCrossMint() public {
        vm.startPrank(deployer);
        persona.setMinter(deployer, true);
        persona.mint(alice);
    }
    // function testSetOwner() public {
    //     vm.startPrank(deployer);
    //     persona.setOwner(alice);
    //     assertEq(persona.owner(), alice);
    // }
    // function testFailSetOwnerZeroAddr() public {
    //     vm.startPrank(deployer);
    //     persona.setOwner(address(0));
    // }
    // function testSetMinterTrue() public {
    //     vm.startPrank(deployer);
    //     persona.setMinter(minter, true);
    //     assertTrue(personaMirror.isMinter(minter));
    // }
    // function testSetMinterFalse() public {
    //     vm.startPrank(deployer);
    //     persona.setMinter(minter, false);
    //     assertTrue(!personaMirror.isMinter(minter));
    // }
    // /// Minting \\\
    // function _mintTo(address recipient) internal returns (uint256 id) {
    //     vm.prank(deployer);
    //     persona.setMinter(minter, true);
    //     vm.prank(minter);
    //     id = personaMirror.mint(recipient);
    // }
    // function testMint() public {
    //     _mintTo(personaOwner);
    //     assertEq(persona.balanceOf(personaOwner), 1);
    //     assertEq(persona.ownerOf(1), personaOwner);
    // }
    // function testFailMintAsNonMinter() public {
    //     vm.prank(deployer);
    //     persona.setMinter(minter, true);
    //     vm.prank(alice);
    //     persona.mint(personaOwner);
    // }
    // /// Impersonation \\\
    // function testImpersonationAsOwner() public {
    //     uint256 id = _mintTo(personaOwner);
    //     vm.startPrank(personaOwner);
    //     personaMirror.impersonate(id, address(consumer));
    //     vm.stopPrank();
    //     assertTrue(personaMirror.getActivePersona(personaOwner, address(consumer)) == id);
    // }
    // function testImpersonationAsConsumerSpecific() public {
    //     uint256 id = _mintTo(personaOwner);
    //     _authorizeConsumerSpecific(id, alice, address(consumer));
    //     vm.startPrank(alice);
    //     personaMirror.impersonate(id, address(consumer));
    //     assertTrue(personaMirror.getActivePersona(address(alice), address(consumer)) == id);
    //     vm.stopPrank();
    // }
    // function testImpersonationAsFunctionSpecific() public {
    //     uint256 id = _mintTo(personaOwner);
    //     bytes4[] memory fnSignatures = new bytes4[](1);
    //     bytes4 selector = consumer.foo.selector;
    //     fnSignatures[0] = selector;
    //     _authorizeFunctionSpecific(id, alice, address(consumer), fnSignatures);
    //     vm.startPrank(alice);
    //     personaMirror.impersonate(id, address(consumer));
    //     assertTrue(personaMirror.getActivePersona(address(alice), address(consumer)) == id);
    //     vm.stopPrank();
    // }
    // function testFailImpersonationWithoutPermissions() public {
    //     uint256 id = _mintTo(personaOwner);
    //     personaMirror.impersonate(id, address(consumer));
    // }
    // /// Deimpersonation \\\
    // function testDeimpersonation() public {
    //     uint256 id = _mintTo(personaOwner);
    //     _authorizeConsumerSpecific(id, alice, address(consumer));
    //     vm.startPrank(alice);
    //     personaMirror.impersonate(id, address(consumer));
    //     assertTrue(personaMirror.getActivePersona(address(alice), address(consumer)) == id);
    //     personaMirror.deimpersonate(address(consumer));
    //     assertTrue(personaMirror.getActivePersona(address(alice), address(consumer)) == uint256(0));
    //     vm.stopPrank();
    // }
    // /// Authorization \\\
    // function _authorizeConsumerSpecific(
    //     uint256 id,
    //     address user,
    //     address targetConsumer
    // ) internal {
    //     vm.startPrank(personaOwner);
    //     personaMirror.authorize(id, user, targetConsumer, new bytes4[](0));
    //     vm.stopPrank();
    // }
    // function _authorizeFunctionSpecific(
    //     uint256 id,
    //     address user,
    //     address targetConsumer,
    //     bytes4[] memory fnSignatures
    // ) internal {
    //     vm.startPrank(personaOwner);
    //     personaMirror.authorize(id, user, targetConsumer, fnSignatures);
    //     vm.stopPrank();
    // }
    // function testAuthorizeConsumerSpecific() public {
    //     uint256 id = _mintTo(personaOwner);
    //     _authorizeConsumerSpecific(id, alice, address(consumer));
    //     assertEq(uint256(personaMirror.getPermission(id, alice)), uint256(PersonaPermission.CONSUMER_SPECIFIC));
    //     // Test that alice can now call consumer's foo() function
    //     vm.startPrank(alice);
    //     personaMirror.impersonate(id, address(consumer));
    //     uint256 fooResult = consumer.foo();
    //     assertEq(fooResult, id);
    //     vm.stopPrank();
    // }
    // function testAuthorizeFunctionSpecific() public {
    //     uint256 id = _mintTo(personaOwner);
    //     bytes4[] memory fnSignatures = new bytes4[](1);
    //     bytes4 selector = consumer.foo.selector;
    //     fnSignatures[0] = selector;
    //     _authorizeFunctionSpecific(id, alice, address(consumer), fnSignatures);
    //     // Test that personaMirror contract stores permissions correctly
    //     assertEq(uint256(personaMirror.getPermission(id, alice)), uint256(PersonaPermission.FUNCTION_SPECIFIC));
    //     // Test that alice can now call consumer's foo() function
    //     vm.startPrank(alice);
    //     personaMirror.impersonate(id, address(consumer));
    //     uint256 fooResult = consumer.foo();
    //     assertEq(fooResult, id);
    //     vm.stopPrank();
    // }
    // /// Deauthorization \\\
    // function testDeauthorizeConsumerSpecific() public {
    //     uint256 id = _mintTo(personaOwner);
    //     _authorizeConsumerSpecific(id, alice, address(consumer));
    //     vm.startPrank(personaOwner);
    //     personaMirror.deauthorize(id, alice, address(consumer));
    //     vm.stopPrank();
    //     assertEq(uint256(personaMirror.getPermission(id, alice)), uint256(PersonaPermission.DENY));
    //     assertEq(personaMirror.getActivePersona(alice, address(consumer)), uint256(0));
    //     assertTrue(personaMirror.getAuthorization(id, alice, address(consumer)).isAuthorized == false);
    //     assertEq(personaMirror.getAuthorization(id, alice, address(consumer)).authorizedFns.length, uint256(0));
    // }
    // function testFailMockConsumerCallDeauthorizeConsumerSpecific() public {
    //     uint256 id = _mintTo(personaOwner);
    //     _authorizeConsumerSpecific(id, alice, address(consumer));
    //     vm.startPrank(alice);
    //     personaMirror.impersonate(id, address(consumer));
    //     vm.stopPrank();
    //     vm.startPrank(personaOwner);
    //     personaMirror.deauthorize(id, alice, address(consumer));
    //     vm.stopPrank();
    //     // Test impersonation was removed and alice can no longer call consumer's foo() function
    //     vm.startPrank(alice);
    //     consumer.foo();
    //     vm.stopPrank();
    // }
    // function testDeauthorizeFunctionSpecific() public {
    //     uint256 id = _mintTo(personaOwner);
    //     bytes4[] memory fnSignatures = new bytes4[](1);
    //     bytes4 selector = consumer.foo.selector;
    //     fnSignatures[0] = selector;
    //     _authorizeFunctionSpecific(id, alice, address(consumer), fnSignatures);
    //     vm.startPrank(alice);
    //     personaMirror.impersonate(id, address(consumer));
    //     vm.stopPrank();
    //     vm.startPrank(personaOwner);
    //     personaMirror.deauthorize(id, alice, address(consumer));
    //     vm.stopPrank();
    //     assertEq(uint256(personaMirror.getPermission(id, alice)), uint256(PersonaPermission.DENY));
    //     assertEq(personaMirror.getActivePersona(alice, address(consumer)), uint256(0));
    //     assertTrue(personaMirror.getAuthorization(id, alice, address(consumer)).isAuthorized == false);
    // }
    // function testFailMockConsumerCallDeauthorizeFunctionSpecific() public {
    //     uint256 id = _mintTo(personaOwner);
    //     bytes4[] memory fnSignatures = new bytes4[](1);
    //     bytes4 selector = consumer.foo.selector;
    //     fnSignatures[0] = selector;
    //     _authorizeFunctionSpecific(id, alice, address(consumer), fnSignatures);
    //     vm.startPrank(alice);
    //     personaMirror.impersonate(id, address(consumer));
    //     vm.stopPrank();
    //     vm.startPrank(personaOwner);
    //     personaMirror.deauthorize(id, alice, address(consumer));
    //     vm.stopPrank();
    //     // Test impersonation was removed and alice can no longer call consumer's foo() function
    //     vm.startPrank(alice);
    //     consumer.foo();
    //     vm.stopPrank();
    // }
    // function testFailConsumerSpecificCallAfterDeimpersonation() public {
    //     uint256 id = _mintTo(personaOwner);
    //     _authorizeConsumerSpecific(id, alice, address(consumer));
    //     vm.startPrank(alice);
    //     personaMirror.impersonate(id, address(consumer));
    //     personaMirror.deimpersonate(address(consumer));
    //     consumer.foo();
    //     vm.stopPrank();
    // }
    // function testFailFunctionSpecificCallAfterDeimpersonation() public {
    //     uint256 id = _mintTo(personaOwner);
    //     bytes4[] memory fnSignatures = new bytes4[](1);
    //     bytes4 selector = consumer.foo.selector;
    //     fnSignatures[0] = selector;
    //     _authorizeFunctionSpecific(id, alice, address(consumer), fnSignatures);
    //     vm.startPrank(alice);
    //     personaMirror.impersonate(id, address(consumer));
    //     personaMirror.deimpersonate(address(consumer));
    //     consumer.foo();
    //     vm.stopPrank();
    // }
    // /// Transfer \\\
    // function testTransferOwnership() public {
    //     uint256 id = _mintTo(personaOwner);
    //     vm.startPrank(personaOwner);
    //     personaMirror.transferFrom(address(personaOwner), address(alice), id);
    //     vm.stopPrank();
    //     assertTrue(personaMirror.ownerOf(id) == address(alice));
    // }
    // function testTransferRemovesAuthorization() public {
    //     uint256 id = _mintTo(personaOwner);
    //     vm.startPrank(personaOwner);
    //     personaMirror.authorize(id, personaOwner, address(consumer), new bytes4[](0));
    //     personaMirror.transferFrom(personaOwner, address(alice), id);
    //     vm.stopPrank();
    //     assertTrue(personaMirror.getAuthorization(id, personaOwner, address(consumer)).isAuthorized == false);
    // }
    // function testFailTransferRemovesImpersonation() public {
    //     uint256 id = _mintTo(personaOwner);
    //     vm.startPrank(personaOwner);
    //     personaMirror.impersonate(id, address(consumer));
    //     personaMirror.transferFrom(personaOwner, address(alice), id);
    //     personaMirror.deimpersonate(address(consumer));
    //     vm.stopPrank();
    // }
}
