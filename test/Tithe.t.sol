// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/Tithe.sol";

contract TitheTest is Test {
    Tithe tithe;

    address deployer = address(this);
    address church = address(0xC4);
    address alice = address(0xA1);
    address bob = address(0xB0);

    uint256 constant INITIAL_SUPPLY = 1_000_000 ether;
    uint256 constant TITHE_BPS = 1000; // 10%

    function setUp() public {
        tithe = new Tithe("Tithe Token", "TITHE", INITIAL_SUPPLY, church, TITHE_BPS);
        tithe.transfer(alice, 10_000 ether);
    }

    function testInitialState() public view {
        assertEq(tithe.name(), "Tithe Token");
        assertEq(tithe.symbol(), "TITHE");
        assertEq(tithe.decimals(), 18);
        assertEq(tithe.totalSupply(), INITIAL_SUPPLY);
        assertEq(tithe.owner(), deployer);
        assertEq(tithe.titheRecipient(), church);
        assertEq(tithe.titheBps(), TITHE_BPS);
        assertTrue(tithe.titheActive());
    }

    function testInitialTransferRoutedTithe() public view {
        assertEq(tithe.balanceOf(alice), 9_000 ether);
        assertEq(tithe.balanceOf(church), 1_000 ether);
        assertEq(tithe.totalTithed(), 1_000 ether);
        assertEq(tithe.titheCount(), 1);
    }

    function testTransferRoutesTithe() public {
        vm.prank(alice);
        tithe.transfer(bob, 1_000 ether);

        assertEq(tithe.balanceOf(bob), 900 ether);
        assertEq(tithe.balanceOf(church), 1_100 ether);
        assertEq(tithe.balanceOf(alice), 8_000 ether);
        assertEq(tithe.totalTithed(), 1_100 ether);
        assertEq(tithe.titheCount(), 2);
    }

    function testPreviewTithe() public view {
        (uint256 titheAmt, uint256 netAmt) = tithe.previewTithe(1_000 ether);
        assertEq(titheAmt, 100 ether);
        assertEq(netAmt, 900 ether);
    }

    function testTitheRoutedEventEmitted() public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit Tithe.TitheRouted(alice, bob, church, 1_000 ether, 100 ether, 900 ether);
        tithe.transfer(bob, 1_000 ether);
    }

    function testTransferToTitheRecipientSkipsTithe() public {
        vm.prank(alice);
        tithe.transfer(church, 1_000 ether);

        assertEq(tithe.balanceOf(church), 2_000 ether);
        assertEq(tithe.balanceOf(alice), 8_000 ether);
    }

    function testTransferFromTitheRecipientSkipsTithe() public {
        vm.prank(church);
        tithe.transfer(bob, 500 ether);

        assertEq(tithe.balanceOf(bob), 500 ether);
        assertEq(tithe.balanceOf(church), 500 ether);
    }

    function testSetTitheBps() public {
        tithe.setTitheBps(2000);
        assertEq(tithe.titheBps(), 2000);

        vm.prank(alice);
        tithe.transfer(bob, 1_000 ether);
        assertEq(tithe.balanceOf(bob), 800 ether);
    }

    function testSetTitheBpsRevertAboveCap() public {
        vm.expectRevert(Tithe.TitheBpsTooHigh.selector);
        tithe.setTitheBps(5001);
    }

    function testSetTitheRecipient() public {
        address newChurch = address(0xCC);
        tithe.setTitheRecipient(newChurch);
        assertEq(tithe.titheRecipient(), newChurch);

        vm.prank(alice);
        tithe.transfer(bob, 1_000 ether);
        assertEq(tithe.balanceOf(newChurch), 100 ether);
    }

    function testPauseTithe() public {
        tithe.setTitheActive(false);

        vm.prank(alice);
        tithe.transfer(bob, 1_000 ether);

        assertEq(tithe.balanceOf(bob), 1_000 ether);
        assertEq(tithe.balanceOf(church), 1_000 ether);
    }

    function testNonOwnerCannotAdmin() public {
        vm.prank(alice);
        vm.expectRevert(Tithe.NotOwner.selector);
        tithe.setTitheBps(2000);
    }

    function testZeroTitheBpsSkipsRouting() public {
        tithe.setTitheBps(0);

        vm.prank(alice);
        tithe.transfer(bob, 1_000 ether);

        assertEq(tithe.balanceOf(bob), 1_000 ether);
    }

    function testInsufficientBalanceReverts() public {
        vm.prank(bob);
        vm.expectRevert(Tithe.InsufficientBalance.selector);
        tithe.transfer(alice, 1 ether);
    }

    function testTransferFromWithAllowance() public {
        vm.prank(alice);
        tithe.approve(bob, 1_000 ether);

        vm.prank(bob);
        tithe.transferFrom(alice, bob, 1_000 ether);

        assertEq(tithe.balanceOf(bob), 900 ether);
        assertEq(tithe.allowance(alice, bob), 0);
    }
}
