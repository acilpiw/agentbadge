// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "solady/tokens/ERC721.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Base64} from "solady/utils/Base64.sol";

/// @title AgentBadge — free claim badge for Binance Agent ID holders
/// @notice Built for the Binance Agent ID Hackathon (Nov–Dec 2026).
///         Any address holding an Agent ID (SPACE ID Agent ID, ERC-721,
///         non-transferable) can claim exactly one badge, gas only.
///         The contract takes no payments and asks for no approvals.
/// @dev Owner permissions (disclosed): `withdraw` only — recovers BNB that
///      was accidentally sent to the contract. No pause, no freeze,
///      no mint tax, no transfer restriction, no metadata admin key.
interface IAgentID {
    function balanceOf(address owner) external view returns (uint256);
}

contract AgentBadge is ERC721, Ownable {
    using LibString for uint256;

    IAgentID public constant AGENT_ID =
        IAgentID(0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F);

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public totalClaimed;

    mapping(address => bool) public hasClaimed;
    mapping(uint256 => string) public taglineOf;

    event Claimed(address indexed holder, uint256 indexed tokenId, string tagline);

    error NotAgentIDHolder();
    error AlreadyClaimed();
    error SoldOut();
    error TaglineTooLong();
    error TaglineHasUnsafeChars();

    constructor() {
        _initializeOwner(msg.sender);
    }

    function name() public pure override returns (string memory) {
        return "AgentBadge";
    }

    function symbol() public pure override returns (string memory) {
        return "AGBADGE";
    }

    /// @notice Claim one free badge. Caller must hold an Agent ID.
    /// @param tagline Optional one-line agent tagline (max 140 chars, no <>&").
    function claim(string calldata tagline) external {
        if (AGENT_ID.balanceOf(msg.sender) == 0) revert NotAgentIDHolder();
        if (hasClaimed[msg.sender]) revert AlreadyClaimed();
        if (totalClaimed >= MAX_SUPPLY) revert SoldOut();
        if (bytes(tagline).length > 140) revert TaglineTooLong();
        _validateTagline(tagline);

        hasClaimed[msg.sender] = true;
        uint256 tokenId = ++totalClaimed;
        if (bytes(tagline).length > 0) taglineOf[tokenId] = tagline;

        _mint(msg.sender, tokenId);
        emit Claimed(msg.sender, tokenId, tagline);
    }

    function _validateTagline(string calldata tagline) internal pure {
        bytes calldata b = bytes(tagline);
        for (uint256 i; i < b.length; ++i) {
            bytes1 c = b[i];
            if (c == "<" || c == ">" || c == "&" || c == '"' || c < 0x20) {
                revert TaglineHasUnsafeChars();
            }
        }
    }

    /// @notice Fully on-chain metadata: no external server or IPFS dependency.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        string memory svg = _svg(tokenId);
        string memory json = string.concat(
            '{"name":"AgentBadge #',
            tokenId.toString(),
            '","description":"Free badge for Binance Agent ID holders. Claimable once per Agent ID holder, gas only.","image":"data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '","attributes":[{"trait_type":"Badge","value":"Agent ID Holder"}]}'
        );
        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    function _svg(uint256 tokenId) internal view returns (string memory) {
        string memory tag = taglineOf[tokenId];
        string memory tagLine = bytes(tag).length > 0
            ? string.concat(
                '<text x="40" y="270" font-family="monospace" font-size="22" fill="#f0b90b">',
                tag,
                "</text>"
            )
            : "";
        return string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="640" height="360" viewBox="0 0 640 360">',
            '<rect width="640" height="360" fill="#0b0e11"/>',
            '<rect x="16" y="16" width="608" height="328" fill="none" stroke="#f0b90b" stroke-width="3"/>',
            '<text x="40" y="90" font-family="monospace" font-size="44" font-weight="bold" fill="#f0b90b">AGENTBADGE</text>',
            '<text x="40" y="150" font-family="monospace" font-size="28" fill="#ffffff">Agent ID Holder #',
            tokenId.toString(),
            "</text>",
            '<text x="40" y="200" font-family="monospace" font-size="20" fill="#848e9c">BNB Chain &#183; Free claim, gas only</text>',
            tagLine,
            "</svg>"
        );
    }

    /// @notice Recover BNB accidentally sent to the contract. Nothing else.
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}
}
