// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AgentBadge} from "../src/AgentBadge.sol";

interface IAgentID {
    function balanceOf(address owner) external view returns (uint256);
}

contract AgentBadgeTest is Test {
    AgentBadge public badge;

    address public constant AGENT_WALLET = 0x369338341D0DA99FE2872344a40229FEa2562F50;
    address public constant NON_HOLDER = 0x000000000000000000000000000000000000dEaD;

    function setUp() public {
        vm.createSelectFork("https://bsc-dataseed.binance.org/");
        badge = new AgentBadge();
    }

    function testAgentWalletHoldsAgentID() public view {
        assertEq(IAgentID(0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F).balanceOf(AGENT_WALLET), 1);
    }

    function testClaimByHolder() public {
        vm.prank(AGENT_WALLET);
        badge.claim("hello agents");
        assertEq(badge.totalClaimed(), 1);
        assertEq(badge.ownerOf(1), AGENT_WALLET);
        assertEq(badge.taglineOf(1), "hello agents");
        assertTrue(badge.hasClaimed(AGENT_WALLET));
    }

    function testClaimEmptyTagline() public {
        vm.prank(AGENT_WALLET);
        badge.claim("");
        assertEq(badge.totalClaimed(), 1);
        assertEq(bytes(badge.tokenURI(1)).length > 0, true);
    }

    function testNonHolderReverts() public {
        vm.prank(NON_HOLDER);
        vm.expectRevert(AgentBadge.NotAgentIDHolder.selector);
        badge.claim("");
    }

    function testDoubleClaimReverts() public {
        vm.prank(AGENT_WALLET);
        badge.claim("");
        vm.prank(AGENT_WALLET);
        vm.expectRevert(AgentBadge.AlreadyClaimed.selector);
        badge.claim("");
    }

    function testLongTaglineReverts() public {
        vm.prank(AGENT_WALLET);
        vm.expectRevert(AgentBadge.TaglineTooLong.selector);
        badge.claim(
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        );
    }

    function testUnsafeTaglineReverts() public {
        vm.prank(AGENT_WALLET);
        vm.expectRevert(AgentBadge.TaglineHasUnsafeChars.selector);
        badge.claim("<script>");
    }

    function testTokenURIPrefix() public {
        vm.prank(AGENT_WALLET);
        badge.claim("");
        string memory uri = badge.tokenURI(1);
        assertEq(bytes(uri).length > 29, true);
        assertEq(
            keccak256(bytes(_slice(uri, 0, 29))),
            keccak256(bytes("data:application/json;base64,"))
        );
    }

    function _slice(string memory s, uint256 start, uint256 len) internal pure returns (string memory) {
        bytes memory b = bytes(s);
        bytes memory out = new bytes(len);
        for (uint256 i; i < len; ++i) out[i] = b[start + i];
        return string(out);
    }
}
