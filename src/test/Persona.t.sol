// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {BaseTest, console} from "./base/BaseTest.sol";

import {MockL2Bridge} from "./mocks/MockL2Bridge.sol";
import {MockConsumer} from "./mocks/MockConsumer.sol";
import {Persona} from "../L1/Persona.sol";
import {EmptyPersonaTokenURIGenerator} from "../L1/EmptyPersonaTokenURIGenerator.sol";
import {PersonaMirror} from "../L2/PersonaMirror.sol";
import "./utils/console.sol";

contract PersonaTest is BaseTest {
    MockL2Bridge bridge;
    Persona persona;
    EmptyPersonaTokenURIGenerator tokenURIGenerator;
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
        tokenURIGenerator = new EmptyPersonaTokenURIGenerator();
        persona = new Persona("L", "L", address(bridge), address(0));
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

    function testSetTokenURIGenerator() public {
        vm.prank(deployer);
        persona.setPersonaTokenURIGeneratorAddress(address(tokenURIGenerator));
        assertEq(address(persona.personaTokenURIGenerator()), address(tokenURIGenerator));
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
        personaMirror.authorize(id, user, targetConsumer, new bytes4[](0));
    }

    function _authorizeFunctionSpecific(
        uint256 id,
        address user,
        address targetConsumer
    ) internal {
        bytes4[] memory fnSignatures = new bytes4[](1);
        bytes4 selector = consumer.foo.selector;
        fnSignatures[0] = selector;

        personaMirror.authorize(id, user, targetConsumer, fnSignatures);
    }

    function testAuthorizeConsumerSpecific() public {
        uint256 id = _mintTo(personaOwner);

        // Authorize Alice to impersonate as `id`
        vm.prank(personaOwner);
        _authorizeConsumerSpecific(id, alice, address(consumer));

        // Alice should be authorized to call any function
        assertTrue(personaMirror.isAuthorized(id, alice, address(consumer), 0xdeadbeef));

        // Test that alice can now call consumer's foo() function
        vm.startPrank(alice);
        personaMirror.impersonate(id, address(consumer));
        uint256 fooResult = consumer.foo();
        vm.stopPrank();

        assertEq(fooResult, id);
    }

    function testAuthorizeFunctionSpecific() public {
        uint256 id = _mintTo(personaOwner);

        // Authorize Alice to impersonate as `id`
        vm.prank(personaOwner);
        _authorizeFunctionSpecific(id, alice, address(consumer));

        // Alice should be authorized to call foo()
        assertTrue(personaMirror.isAuthorized(id, alice, address(consumer), consumer.foo.selector));

        // Alice should not be authorized to call any function
        assertTrue(!personaMirror.isAuthorized(id, alice, address(consumer), 0xdeadbeef));

        // Test that alice can now call consumer's foo() function
        vm.startPrank(alice);
        personaMirror.impersonate(id, address(consumer));
        uint256 fooResult = consumer.foo();
        vm.stopPrank();

        assertEq(fooResult, id);
    }

    function testDeauthorizeConsumerSpecific() public {
        uint256 id = _mintTo(personaOwner);

        // Authorize Alice to impersonate as `id`
        vm.prank(personaOwner);
        _authorizeConsumerSpecific(id, alice, address(consumer));

        // `personaOwner` deauthorize Alice
        vm.prank(personaOwner);
        personaMirror.deauthorize(id, alice, address(consumer));

        // Alice should not be authorized for `id` anymore
        assertTrue(!personaMirror.isAuthorized(id, alice, address(consumer), 0));

        // Alice should not have an active impersonation
        assertEq(personaMirror.getActivePersona(alice, address(consumer)), 0);
    }

    function testDeauthorizeFunctionSpecific() public {
        uint256 id = _mintTo(personaOwner);

        // Authorize Alice to impersonate as `id`
        vm.prank(personaOwner);
        _authorizeFunctionSpecific(id, alice, address(consumer));

        // Alice impersonates as `id`
        vm.prank(alice);
        personaMirror.impersonate(id, address(consumer));

        // `personaOwner` deauthorize Alice
        vm.prank(personaOwner);
        personaMirror.deauthorize(id, alice, address(consumer));

        // Alice should not be authorized for `id` anymore
        assertTrue(!personaMirror.isAuthorized(id, alice, address(consumer), consumer.foo.selector));

        // Alice should not have an active impersonation
        assertEq(personaMirror.getActivePersona(alice, address(consumer)), 0);
    }

    function testDeauthorizeNoActiveImpersonation() public {
        address personaOwner1 = personaOwner;
        address personaOwner2 = bob;
        uint256 id1 = _mintTo(personaOwner1);
        uint256 id2 = _mintTo(personaOwner2);

        // Give alice authorization to 2 different personas
        vm.prank(personaOwner1);
        _authorizeFunctionSpecific(id1, alice, address(consumer));

        vm.prank(personaOwner2);
        _authorizeFunctionSpecific(id2, alice, address(consumer));

        // Alice impersonates `id1`
        vm.prank(alice);
        personaMirror.impersonate(id1, address(consumer));

        // `personaOwner2` deauthorizes Alice
        vm.prank(personaOwner2);
        personaMirror.deauthorize(id2, alice, address(consumer));

        // Alice should be deauthorized from persona `id1`
        assertTrue(!personaMirror.isAuthorized(id2, alice, address(consumer), consumer.foo.selector));

        // Alice's impersonation for `id1` should stay active
        assertEq(personaMirror.getActivePersona(alice, address(consumer)), id1);
    }

    // Impersonation/Deimpersonation \\
    function testImpersonationAsOwner() public {
        uint256 id = _mintTo(personaOwner);

        // `personaOwner` impersonates as `id`
        vm.prank(personaOwner);
        personaMirror.impersonate(id, address(consumer));

        // `personaOwner` should have `id` as active persona
        assertEq(personaMirror.getActivePersona(personaOwner, address(consumer)), id);
    }

    function testImpersonationAsConsumerSpecific() public {
        uint256 id = _mintTo(personaOwner);

        // Give Alice authorization to impersonate `id`
        vm.prank(personaOwner);
        _authorizeConsumerSpecific(id, alice, address(consumer));

        // Alice impersonates `id`
        vm.prank(alice);
        personaMirror.impersonate(id, address(consumer));

        // Alice should have `id` as active persona
        assertEq(personaMirror.getActivePersona(address(alice), address(consumer)), id);
    }

    function testImpersonationAsFunctionSpecific() public {
        uint256 id = _mintTo(personaOwner);

        // Give Alice authorization to impersonate `id`
        vm.prank(personaOwner);
        _authorizeFunctionSpecific(id, alice, address(consumer));

        // Alice impersonates `id`
        vm.prank(alice);
        personaMirror.impersonate(id, address(consumer));

        // Alice should have `id` as active persona
        assertEq(personaMirror.getActivePersona(address(alice), address(consumer)), id);
    }

    function testFailImpersonationWithoutPermissions() public {
        uint256 id = _mintTo(personaOwner);

        // Alice should not be able to impersonate `id`
        vm.prank(alice);
        personaMirror.impersonate(id, address(consumer));
    }

    function testDeimpersonation() public {
        uint256 id = _mintTo(personaOwner);

        // Give Alice authorization to impersonate `id`
        vm.prank(personaOwner);
        _authorizeConsumerSpecific(id, alice, address(consumer));

        // Alice impersonates `id`
        vm.prank(alice);
        personaMirror.impersonate(id, address(consumer));

        // Alice should have `id` as active persona
        assertTrue(personaMirror.getActivePersona(address(alice), address(consumer)) == id);

        // Alice deimpersonates `id`
        vm.prank(alice);
        personaMirror.deimpersonate(address(consumer));

        // Alice should not have an active impersonation
        assertEq(personaMirror.getActivePersona(address(alice), address(consumer)), 0);
    }

    // Consumer Integration \\
    function testFailMockConsumerCallDeauthorizeConsumerSpecific() public {
        uint256 id = _mintTo(personaOwner);

        // Give Alice authorization to impersonate `id`
        vm.prank(personaOwner);
        _authorizeConsumerSpecific(id, alice, address(consumer));

        // Alice impersonates `id`
        vm.prank(alice);
        personaMirror.impersonate(id, address(consumer));

        // `personaOwner` deauthorizes Alice
        vm.prank(personaOwner);
        personaMirror.deauthorize(id, alice, address(consumer));

        // Test impersonation was removed and alice can no longer call consumer's foo() function
        vm.prank(alice);
        consumer.foo();
    }

    function testFailMockConsumerCallDeauthorizeFunctionSpecific() public {
        uint256 id = _mintTo(personaOwner);

        // Give Alice authorization to impersonate `id`
        vm.prank(personaOwner);
        _authorizeFunctionSpecific(id, alice, address(consumer));

        // Alice impersonates `id`
        vm.prank(alice);
        personaMirror.impersonate(id, address(consumer));

        // `personaOwner` deauthorizes Alice
        vm.prank(personaOwner);
        personaMirror.deauthorize(id, alice, address(consumer));

        // Test impersonation was removed and alice can no longer call consumer's foo() function
        vm.prank(alice);
        consumer.foo();
    }

    function testFailConsumerSpecificCallAfterDeimpersonation() public {
        uint256 id = _mintTo(personaOwner);

        // Give Alice authorization to impersonate `id`
        vm.prank(personaOwner);
        _authorizeConsumerSpecific(id, alice, address(consumer));

        // Alice impersonates `id`
        vm.startPrank(alice);
        personaMirror.impersonate(id, address(consumer));

        // Alice deimpersonates `id`
        personaMirror.deimpersonate(address(consumer));

        // Test impersonation was removed and alice can no longer call consumer's foo() function
        consumer.foo();
        vm.stopPrank();
    }

    function testFailFunctionSpecificCallAfterDeimpersonation() public {
        uint256 id = _mintTo(personaOwner);

        // Give Alice authorization to impersonate `id`
        vm.prank(personaOwner);
        _authorizeFunctionSpecific(id, alice, address(consumer));

        // Alice impersonates `id`
        vm.startPrank(alice);
        personaMirror.impersonate(id, address(consumer));

        // Alice deimpersonates `id`
        personaMirror.deimpersonate(address(consumer));

        // Test impersonation was removed and alice can no longer call consumer's foo() function
        consumer.foo();
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                                BRIDGING
    //////////////////////////////////////////////////////////////*/
    // Transfer \\
    function testTransferOwnership() public {
        uint256 id = _mintTo(personaOwner);

        // `personaOwner` transfers persona to Alice
        vm.prank(personaOwner);
        persona.transferFrom(personaOwner, alice, id);

        // Persona Mirror should show Alice as the new owner
        assertEq(personaMirror.ownerOf(id), alice);
    }

    function testTransferRemovesAuthorization() public {
        uint256 id = _mintTo(personaOwner);

        // Give Alice authorization to impersonate `id`
        vm.prank(personaOwner);
        _authorizeConsumerSpecific(id, alice, address(consumer));

        // `personaOwner` transfers persona to Bob
        vm.prank(personaOwner);
        persona.transferFrom(personaOwner, address(bob), id);

        // Alice should be deauthorized from persona `id`
        assertTrue(!personaMirror.isAuthorized(id, alice, address(consumer), bytes4(0)));
    }

    function testTransferRemovesImpersonation() public {
        uint256 id = _mintTo(personaOwner);

        // Give Alice authorization to impersonate `id`
        vm.prank(personaOwner);
        _authorizeConsumerSpecific(id, alice, address(consumer));

        // Alice impersonates `id`
        vm.startPrank(alice);
        personaMirror.impersonate(id, address(consumer));

        // `personaOwner` transfers persona to Bob
        vm.startPrank(personaOwner);
        persona.transferFrom(personaOwner, bob, id);

        // Alice should not have an active impersonation
        assertEq(personaMirror.getActivePersona(personaOwner, address(consumer)), 0);
    }
}
