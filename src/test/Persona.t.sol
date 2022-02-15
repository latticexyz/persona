// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {BaseTest, console} from "./base/BaseTest.sol";

import {MockL2Bridge} from "./mocks/MockL2Bridge.sol";
import {MockConsumer} from "./mocks/MockConsumer.sol";
import {Persona} from "../L1/Persona.sol";
import {PersonaMirror} from "../L2/PersonaMirror.sol";
import "./utils/console.sol";

contract PersonaTest is BaseTest {
    MockL2Bridge bridge;
    Persona persona;
    PersonaMirror personaMirror;
    MockConsumer consumer;

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
        consumer = new MockConsumer(address(personaMirror));
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                            PERSONA TESTS
    //////////////////////////////////////////////////////////////*/
    // Access Control \\
    function testSetOwner() public {
        vm.prank(deployer);
        persona.setOwner(alice);
        assertEq(persona.contractOwner(), alice);
    }

    function testFailSetOwnerZeroAddr() public {
        vm.prank(deployer);
        persona.setOwner(address(0));
    }

    function testSetMinterTrue() public {
        vm.prank(deployer);
        persona.setMinter(minter, true);
        assertTrue(persona.isMinter(minter));
    }

    function testSetMinterFalse() public {
        vm.prank(deployer);
        persona.setMinter(minter, false);
        assertTrue(!persona.isMinter(minter));
    }

    // Minting \\
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

    /*///////////////////////////////////////////////////////////////
                        PERSONA MIRROR TESTS
    //////////////////////////////////////////////////////////////*/
    // Authorization/Deauthorization \\
    function _authorizeConsumerSpecific(
        uint256 id,
        address user,
        address targetConsumer
    ) internal {
        vm.prank(personaOwner);
        personaMirror.authorize(id, user, targetConsumer, new bytes4[](0));
    }

    function _authorizeFunctionSpecific(
        uint256 id,
        address user,
        address targetConsumer,
        bytes4[] memory fnSignatures
    ) internal {
        vm.prank(personaOwner);
        personaMirror.authorize(id, user, targetConsumer, fnSignatures);
    }

    function testAuthorizeConsumerSpecific() public {
        uint256 id = _mintTo(personaOwner);

        _authorizeConsumerSpecific(id, alice, address(consumer));

        assertEq(
            uint256(personaMirror.getPermission(id, alice)),
            uint256(PersonaMirror.PersonaPermission.CONSUMER_SPECIFIC)
        );

        // Test that alice can now call consumer's foo() function
        vm.startPrank(alice);
        personaMirror.impersonate(id, address(consumer));
        uint256 fooResult = consumer.foo();
        vm.stopPrank();

        assertEq(fooResult, id);
    }

    function testAuthorizeFunctionSpecific() public {
        uint256 id = _mintTo(personaOwner);
        bytes4[] memory fnSignatures = new bytes4[](1);
        bytes4 selector = consumer.foo.selector;
        fnSignatures[0] = selector;

        _authorizeFunctionSpecific(id, alice, address(consumer), fnSignatures);

        // Test that personaMirror contract stores permissions correctly
        assertEq(
            uint256(personaMirror.getPermission(id, alice)),
            uint256(PersonaMirror.PersonaPermission.FUNCTION_SPECIFIC)
        );

        // Test that alice can now call consumer's foo() function
        vm.startPrank(alice);
        personaMirror.impersonate(id, address(consumer));
        uint256 fooResult = consumer.foo();
        vm.stopPrank();

        assertEq(fooResult, id);
    }

    function testDeauthorizeConsumerSpecific() public {
        uint256 id = _mintTo(personaOwner);

        _authorizeConsumerSpecific(id, alice, address(consumer));

        vm.prank(personaOwner);
        personaMirror.deauthorize(id, alice, address(consumer));

        assertEq(uint256(personaMirror.getPermission(id, alice)), uint256(PersonaMirror.PersonaPermission.DENY));
        assertEq(personaMirror.getActivePersona(alice, address(consumer)), uint256(0));
        assertTrue(personaMirror.getAuthorization(id, alice, address(consumer)).isAuthorized == false);
        assertEq(personaMirror.getAuthorization(id, alice, address(consumer)).authorizedFns.length, uint256(0));
    }

    function testDeauthorizeFunctionSpecific() public {
        uint256 id = _mintTo(personaOwner);
        bytes4[] memory fnSignatures = new bytes4[](1);
        bytes4 selector = consumer.foo.selector;
        fnSignatures[0] = selector;

        _authorizeFunctionSpecific(id, alice, address(consumer), fnSignatures);

        vm.prank(alice);
        personaMirror.impersonate(id, address(consumer));

        vm.prank(personaOwner);
        personaMirror.deauthorize(id, alice, address(consumer));

        assertEq(uint256(personaMirror.getPermission(id, alice)), uint256(PersonaMirror.PersonaPermission.DENY));
        assertEq(personaMirror.getActivePersona(alice, address(consumer)), uint256(0));
        assertTrue(personaMirror.getAuthorization(id, alice, address(consumer)).isAuthorized == false);
    }

    function testDeauthorizeNoActiveImpersonation() public {
        uint256 id1 = _mintTo(personaOwner);
        uint256 id2 = _mintTo(bob);
        bytes4[] memory fnSignatures = new bytes4[](1);
        bytes4 selector = consumer.foo.selector;
        fnSignatures[0] = selector;

        _authorizeFunctionSpecific(id1, alice, address(consumer), fnSignatures);

        vm.prank(bob);
        personaMirror.authorize(id2, alice, address(consumer), fnSignatures);

        vm.prank(alice);
        personaMirror.impersonate(id2, address(consumer));

        vm.prank(personaOwner);
        personaMirror.deauthorize(id1, alice, address(consumer));

        assertEq(uint256(personaMirror.getPermission(id1, alice)), uint256(PersonaMirror.PersonaPermission.DENY));
        assertTrue(personaMirror.getAuthorization(id1, alice, address(consumer)).isAuthorized == false);

        // The impersonation for `id2` should stay active
        assertEq(personaMirror.getActivePersona(alice, address(consumer)), uint256(id2));
    }

    // Impersonation/Deimpersonation \\
    function testImpersonationAsOwner() public {
        uint256 id = _mintTo(personaOwner);

        vm.prank(personaOwner);
        personaMirror.impersonate(id, address(consumer));

        assertTrue(personaMirror.getActivePersona(personaOwner, address(consumer)) == id);
    }

    function testImpersonationAsConsumerSpecific() public {
        uint256 id = _mintTo(personaOwner);

        _authorizeConsumerSpecific(id, alice, address(consumer));

        vm.prank(alice);
        personaMirror.impersonate(id, address(consumer));

        assertTrue(personaMirror.getActivePersona(address(alice), address(consumer)) == id);
    }

    function testImpersonationAsFunctionSpecific() public {
        uint256 id = _mintTo(personaOwner);
        bytes4[] memory fnSignatures = new bytes4[](1);
        bytes4 selector = consumer.foo.selector;
        fnSignatures[0] = selector;

        _authorizeFunctionSpecific(id, alice, address(consumer), fnSignatures);

        vm.prank(alice);
        personaMirror.impersonate(id, address(consumer));

        assertTrue(personaMirror.getActivePersona(address(alice), address(consumer)) == id);
    }

    function testFailImpersonationWithoutPermissions() public {
        uint256 id = _mintTo(personaOwner);

        personaMirror.impersonate(id, address(consumer));
    }

    function testDeimpersonation() public {
        uint256 id = _mintTo(personaOwner);

        _authorizeConsumerSpecific(id, alice, address(consumer));

        vm.prank(alice);
        personaMirror.impersonate(id, address(consumer));
        assertTrue(personaMirror.getActivePersona(address(alice), address(consumer)) == id);

        vm.prank(alice);
        personaMirror.deimpersonate(address(consumer));
        assertTrue(personaMirror.getActivePersona(address(alice), address(consumer)) == uint256(0));
    }

    // Consumer Integration \\
    function testFailMockConsumerCallDeauthorizeConsumerSpecific() public {
        uint256 id = _mintTo(personaOwner);

        _authorizeConsumerSpecific(id, alice, address(consumer));

        vm.prank(alice);
        personaMirror.impersonate(id, address(consumer));

        vm.prank(personaOwner);
        personaMirror.deauthorize(id, alice, address(consumer));

        // Test impersonation was removed and alice can no longer call consumer's foo() function
        vm.prank(alice);
        consumer.foo();
    }

    function testFailMockConsumerCallDeauthorizeFunctionSpecific() public {
        uint256 id = _mintTo(personaOwner);
        bytes4[] memory fnSignatures = new bytes4[](1);
        bytes4 selector = consumer.foo.selector;
        fnSignatures[0] = selector;

        _authorizeFunctionSpecific(id, alice, address(consumer), fnSignatures);

        vm.prank(alice);
        personaMirror.impersonate(id, address(consumer));

        vm.prank(personaOwner);
        personaMirror.deauthorize(id, alice, address(consumer));

        // Test impersonation was removed and alice can no longer call consumer's foo() function
        vm.prank(alice);
        consumer.foo();
    }

    function testFailConsumerSpecificCallAfterDeimpersonation() public {
        uint256 id = _mintTo(personaOwner);

        _authorizeConsumerSpecific(id, alice, address(consumer));

        vm.startPrank(alice);
        personaMirror.impersonate(id, address(consumer));
        personaMirror.deimpersonate(address(consumer));
        consumer.foo();
        vm.stopPrank();
    }

    function testFailFunctionSpecificCallAfterDeimpersonation() public {
        uint256 id = _mintTo(personaOwner);
        bytes4[] memory fnSignatures = new bytes4[](1);
        bytes4 selector = consumer.foo.selector;
        fnSignatures[0] = selector;

        _authorizeFunctionSpecific(id, alice, address(consumer), fnSignatures);

        vm.startPrank(alice);
        personaMirror.impersonate(id, address(consumer));
        personaMirror.deimpersonate(address(consumer));
        consumer.foo();
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                                BRIDGING
    //////////////////////////////////////////////////////////////*/
    // Transfer \\
    function testTransferOwnership() public {
        uint256 id = _mintTo(personaOwner);

        vm.prank(personaOwner);
        persona.transferFrom(address(personaOwner), address(alice), id);

        assertTrue(personaMirror.ownerOf(id) == address(alice));
    }

    function testTransferRemovesAuthorization() public {
        uint256 id = _mintTo(personaOwner);

        vm.startPrank(personaOwner);
        personaMirror.authorize(id, personaOwner, address(consumer), new bytes4[](0));
        persona.transferFrom(personaOwner, address(alice), id);
        vm.stopPrank();

        assertTrue(personaMirror.getAuthorization(id, personaOwner, address(consumer)).isAuthorized == false);
    }

    function testTransferRemovesImpersonation() public {
        uint256 id = _mintTo(personaOwner);

        vm.startPrank(personaOwner);
        personaMirror.impersonate(id, address(consumer));
        persona.transferFrom(personaOwner, address(alice), id);
        vm.stopPrank();

        assertTrue(personaMirror.getActivePersona(personaOwner, address(consumer)) == 0);
    }

    // Nuke \\
    // TODO: @namra need to add test for nuke bridging

    // TODO: @namra we need to more aggressively test the nonce system to make sure that it's working correctly
    // i.e. after a nuke/transfer,
    //      - user who are previously authorized is no longer authorized
    //      - user who are previously impersonating is no longer impersonating
}
