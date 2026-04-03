// ============================================
//    D U N K   P O G E   N F T
//    10,000 Fully On-Chain Tokens
//    Fully Decentralized & Immutable
// ============================================

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/interfaces/IERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * @title Dunk Poge: A 10,000 Fully On-Chain, Generative NFT Collection
 * @notice Fully on-chain generative NFT with randomized traits
 * @dev Max supply: 10,000 | Price: 0.005 ETH | Royalty: 5%
 * @dev OPTIMIZED: Uses ERC721A for batch minting efficiency
 * 
 * EMERGENT RARITY SYSTEM: Rarity is determined by actual mint distribution.
 * Gaming the system makes targeted traits MORE COMMON, creating natural
 * manipulation resistance.
 * 
 * SEED GENERATION: Seeds computed once during minting and stored individually.
 * This balances gas costs at mint time with efficient metadata retrieval.
 */

 /**
 * @notice TEAM RESERVE ALLOCATION
 * @dev The deploying team reserves the right to mint up to 500 NFTs
 * (5% of MAX_SUPPLY) via the airdrop() function prior to or during
 * the public sale. These allocations may be used for, but are not
 * limited to: team compensation, marketing partnerships, community
 * rewards, promotional giveaways, and strategic collaborations.
 */

contract DunkPoge is ERC721AQueryable, ReentrancyGuard, Ownable, IERC2981 {
    using Strings for uint256;

    // ============ Constants ============
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant PRICE = 0.005 ether;
    uint256 public constant MAX_PER_WALLET = 10;
    uint96 public constant ROYALTY_BPS = 500; // 5% royalty
    uint256 public constant MAX_AIRDROP_BATCH = 100;

    // ============ State Variables ============
    bool public saleActive;
    mapping(uint256 => uint256) public tokenIdToSeed; // Individual seed storage
    uint256 private nonce; // Entropy source

    // ============ Color Palettes ============
    string[] private face = ["ivory", "wheat", "peachpuff", "tan", "sandybrown", "goldenrod", "chocolate", "sienna", "royalblue", "limegreen"];
    string[] private eyeColor = ["blue", "green", "gray", "black", "brown", "rebeccapurple", "teal"];
    string[] private lipColors = ["black", "crimson", "deeppink", "purple", "blue", "gold", "cyan"];
    string[] private hairColors = ["black", "saddlebrown", "sienna", "chocolate", "peru", "silver", "crimson", "deeppink", "purple", "royalblue", "forestgreen", "gold", "orange", "teal", "hotpink"];
    string[] private frameColors = ["red", "skyblue", "purple", "black", "hotpink", "cyan", "magenta"];
    string[] private lensColors = ["green", "lime", "yellow", "teal", "pink"];
    string[] private headwearColors = ["green", "lime", "yellow", "tomato", "dodgerblue", "orchid", "turquoise", "gold", "aqua"];

    // ============ SVG Constants ============
    string private constant svgStart = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96">';
    string private constant svgBackground = '<rect width="96" height="96" fill="white" class="t0"/><path d="M64 32v-4h-4v-4h-4v4h-4v4h-4v-4h-4v-4h-4v4h-4v4h-4v4h-4v40h4v20h20v-8h4v-4h4v-4h4v-4h4V32z"/>';
    string private constant eyes = '<path d="M40 52h4v4h-4zm20 0h4v4h-4z" class="wh t75"/><path d="M36 52h4v4h-4zm20 0h4v4h-4z" class="pl"/>';
    string private constant dogeear = '<path class="t50" d="M64 32h4v4h-4z"/><path class="sk t50" d="M44 28h-4v4h-4v4h12v-4h-4zm16 4v-4h-4v4h-4v4h12v-4z"/><path class="t50" d="M44 28h4v4h-4zM48 32h4v4h-4zM52 28h4v4h-4zM56 24h4v4h-4zM60 28h4v4h-4zM40 24h4v4h-4zM32 32h4v4h-4zM36 28h4v4h-4z"/><path class="t25" d="M56 32h4v4h-4zM40 32h4v4h-4z"/>';

    // ============ Hair Styles (80% styled, 20% none) ============
    string[] private hair = [
        '<path class="hr" d="M40 32h4v4h-4zm8 0h4v4h-4zm8 0h4v4h-4zm-20 4h4v4h-4zm8 0h4v4h-4zm8 0h4v4h-4zm8 0h4v4h-4zm-28 4h4v4h-4zm8 0h4v4h-4zm8 0h4v4h-4zm8 0h4v4h-4z"/>',
        '<path class="hr" d="M72 72h-4V60h-4V44h-4v-4h-4v-4h-8v4h4v4h-8v-4h-8v4h-4v16h-4v8h-4v-8h-4v4h-4v-8h4v-4h-4v4h-4v-8h4v-4H8v-4h4v-4h4v-4h-4v-4h4v-4h4v-8h4v4h4v-4h4v4h4v-8h4v4h4v4h4v-4h4v-4h4v4h8v-4h4v12h4v-4h4v8h4v4h-4v4h-4v4h4v4h4v4h-4v8h4v4h-8zM56 8h4v4h-4z"/><path class="hr" d="M24 12h4v4h-4zm52 4h4v4h-4zm-64 4h4v4h-4zm8 48h4v4h-4zm52 4h4v4h-4z"/>',
        '<path class="hr" d="M80 48v-4h-4v-4h4v-4h-8v-4h4v-4h8v-4H68v-4h-4v-8h-8v4h-8v8h-4v-4h-4v-4h-8v4h-8v4h-4v4h-4v4h-4v4h8v4h-4v4h-4v4h4v4h-4v4h4v4h-4v4h4v8h4v4h4v-4h4v-4h4v-4h-4V48h4v-8h8v-4h16v8h4v-4h4v4h4v20h4v-4h4v4h4v-8h4v-8h-4zM24 68h-4v-4h4v1.63l.15 2.37H24zm4-36h-4v-4h4v4zm4-4v-4h4v4h-4zm32 0h-4v-4h4v4z"/><path class="hr" d="M76 64v4h4v4h-8v-8zM44 12h4v4h-4zm24 4h4v4h-4zM40 40h4v4h-4zm40 0h4v4h-4zm-28 4h4v4h-4zm12 20h4v4h-4z"/>',
        '<path class="hr" d="M16 68h4v4h-4zm60-8v-8h-4v-4h4v-4h-4v-4h4v-4h-8v-4h-4v-4h-4v-4h-4v-4H40v4h-4v4h-4v-4h-4v8h-8v4h4v4h-4v4h4v4h-4v4h4v4h-4v-4h-4v4h-4v4h8v8h8V52h4v-4h4v-8h4v-4h4v4h4v12h4V40h8v4h4v4h4v20h4v-4h8v-4z"/><path class="hr" d="M40 40h4v4h-4zm20-20h4v4h-4zm8 8h4v4h-4zm4 4h4v4h-4zm4 16h4v4h-4zm-24 4h4v4h-4zm20 16h4v4h-4zM16 44h4v4h-4z"/>',
        '<path class="hr" d="M68 28v-4h-4v-4h-4v-4H32v4h-4v4h-4v4h-4v44h8V60h4V48h4v-4h4v-4h4v8h4v4h4v-4h4v-8h12v32h4V28z"/><path class="wh t25" d="M36 20h4v4h-4zm-4 4h4v4h-4z"/>',
        '<path class="hr" d="M32 40H20v-4h4v-4h-4v-4h4v-4h4v-4h4v-4h24v4h4v-4h4v8h8v4h-4v8h4v4H60v-4h-4v-4h-4v12h-4v-8h-8v4h-4v-4h-4zm0 0h4v4h-4z"/>',
        '<path class="hr" d="M72 60V40h-4v-8h-4v-4h-8v-4H40v4h-8v4h-4v12h-4v16h4v-8h4v-8h4v-4h16v4h4v-4h4v4h4v36h-4v4h-4v8h12v-4h8V60z"/>',
        '<path class="hr" d="M28 24h8v-4h4v-8h4v8h4v-8h4v8h8v-4h4v8h4v4h8v4h-8v4h12v4h-4v4h4v4h-4v4h-4v4h4v4h-4v8h-4V48h-4V36h-8v-4H36v4h-4v8h-4v24h-4v-4h-4v-4h-4v-4h4v-4h-4v-4h4v-8h-4v-4h4V24h4v4h4v4h4v-4h-4v-4z"/><path class="hr" d="M68 24v-4h12v4H68zm-44 0v-8h4v8h-4zm8-8h4v4h-4zM12 32h4v4h-4z"/>',
        '<path d="M44 28h16V12h-8v4h-4v4h-4v4h-4v4h4z"/><path class="hr" d="M52 16v4h-4v4h-4v8h12V16h-4z"/><path class="t25" d="M44 28v-4h4v4h-4z"/>',
        '<path d="M56 28V16h-4v-4h-4v4h-4v12h4v4h-4v4h12v-4h-4v-4z"/><path class="hr" d="M48 16h4v20h-4z"/>',
        '<path class="hr" d="M48 16v4h-4v4h-4v4h4v4h8V16z"/>',
        '<path class="hr" d="M32 76v12H12V76h4V44h4V32h4v-4h4v-4h8v-4h12v4h4v8h-4v-4h-4v8h-4v4h-4v12h-4v8h-4v16h4z"/>',
        '<path class="hr" d="M64 44h-4v-4H40v4h-4v8h-4v40H20V52h4V40h4v-4h4v-4h4v-4h24v4h4v4h4v52h-4v4H52v-4h4v-4h4v-4h4V44z"/>',
        '<path class="hr" d="M84 32v-4h-4v-4h-8v4h-8v-4h-4v-4H36v4h-4v4h-8v-4h-8v4h-4v4H8v16h4v4h4v-4h4v-8h4v-4h4v8h8v-4h4v-4h20v4h8v-4h4v4h4v8h4v4h4v-4h4V32h-4z"/><path fill="gold" d="M28 28h4v4h-4zm40 4h-4v-4h4v4z"/>',
        '<path class="hr" d="M32 68h4v4h4v4H24v-4h-8v-4h4V44h4V32h4v-8h8v-4h24v4h4v4h4v4h4v28h4v8h4v4H68v4h-8v-4h4V36h-4v-4h-4v4h-4v4h-4v4h-4v-4h-8v-4h-4v32z"/>',
        '<path class="hr" d="M76 68V44h-4v-8h-4v-4h-4v-4h-4v-4H36v4h-4v4h-4v4h-4v12h-4v12h-4v12h-4v4h12v4h12v-8h-4V48h4v-4h8v4h4v-4h16v28h-4v8h12v-4h8v-8z"/>',
        '<path class="hr" d="M28 56h4v4h-4zm20-12h4v4h-4z"/><path class="hr" d="M64 32v-4h-4v-4h-4v-4H36v4h-4v4h-4v8h-4v20h4v-8h4v-4h4v-4h16v4h4v-4h8v16h4V32zm-4 24h4v4h-4z"/>',
        '<path class="hr" d="M76 36v-8h-4v-4h-4v-4h-4v-4H52v-4H40v4H28v4h-4v4h-4v4h-4v8h-4v12h4v12h4v4h4v4h4V44h4v-4h8v-4h16v4h8v12h4v16h4v-8h4V48h4V36h-4z"/>',
        "", "", "", "", "" // Indices 18-22: No hair
    ];

    // ============ Eyewear (60% styled, 40% none) ============
    string[] private eyewear = [
        '<path class="fr" d="M52 44v4h-4v-4H32v4h-4v4h4v4h4v4h8v-4h4v-4h4v4h4v4h8v-4h4V44z"/><path class="gl" d="M36 48h8v8h-8zM56 48h8v8h-8z"/>',
        '<path class="fr" d="M64 44H28v8h4v-4h12v4h8v-4h12v4h4v-8z"/><path class="gl t50" d="M32 48h12v12H32zm20 0h12v12H52z"/>',
        '<path class="fr" d="M36 56h8v4h-8zM28 44v4h4v8h4v-8h8v8h4v-8h4v8h4v-8h8v8h-8v4h12V44z"/><path class="gl" d="M36 48h8v8h-8zm20 0h8v8h-8z"/><path class="t50" d="M36 48h8v4h-8zm20 0h8v4h-8z"/>',
        '<path class="fr" d="M28 44v4h4v8h4v4h8v-4h4v-8h16v-4z"/>',
        '<path class="fr" d="M24 44v4h8v4h4v4h8v-4h4v-4h4v4h4v4h8v-4h4v-8z"/>',
        '<path fill="white" d="M28 44v8h4v8h36V44z"/><path fill="#4292cf" d="M36 48h12v8H36z"/><path fill="#e4443e" d="M52 48h12v8H52z"/>',
        '<path class="fr" d="M72 44h-4v-4H32v4h-4v4h-4v8h4v4h4v4h36v-4h4z"/><path class="wh t50" d="M32 44v4h-4v8h4v4h36V44z"/><path class="wh t50" d="M68 48h-4v-4H36v4h-4v8h4v4h28v-4h4z"/><path class="gl" d="M36 48h28v8H36z"/>',
        '<path class="fr" d="M52 44v4h-4v-4H28v8h-4v4h4v4h4v4h12v-4h4v-8h4v8h4v4h12v-4h4V44z"/><path class="gl" d="M32 48h12v12H32zm24 0h12v12H56z"/><path class="t25" d="M32 48h12v8H32zm24 0h12v8H56z"/><path class="t50" d="M32 48h12v4H32zm24 0h12v4H56z"/>',
        '<path d="M32 32v4h-4v16h4v-4h16v-4h4v4h12v4h4V32z"/><path class="fr" d="M48 36h-4v-4h-8v4h-4v8h4v4h8v-4h4zm20 0h-4v-4h-8v4h-4v8h4v4h8v-4h4z"/><path class="gl" d="M56 36h8v8h-8zm-20 0h8v8h-8z"/><path class="wh t25" d="M40 36v4h-4v-4h4z"/>',
        '<path class="fr" d="M28 44v16h40V44H28zm16 12h-8v-8h8v8zm20 0h-8v-8h8v8z"/><path fill="#d9dcdc" d="M36 52h4v4h-4zm20 0h4v4h-4z"/>',
        '<path class="fr" d="M28 44v4h8v8h8v-8h12v8h8V44z"/>',
        "", "", "", "", "" // Indices 11-15: No eyewear
    ];

     // ============ Accessory Layer 1 ============
    string[] private accessoriesLayer1 = [
        "", "", "", "", "", "", "", "", "", "", "", "", // 0-11: None
        '<path style="opacity:.25;fill:#e4ccc1" d="M36 60h8v4h-4v-4zm28 4h-8v-4h8v4z"/>', // 12: Rosy
        '<path style="opacity:.25;fill:#c0a191" d="M56 36h4v4h-4zm-12 4h4v4h-4zM28 52h4v4h-4zm8 12h4v4h-4zm20-8h4v4h-4zm4 12h4v4h-4zM48 80h4v4h-4z"/>', // 13: Spots
        '<path style="opacity:.25;fill:#b1aeac" d="M36 64h4v4h-4z"/>', // 14: Mole
        '<path fill="#faca28" d="M36 88h12v4H36z"/>', // 15: Chain
        '<path fill="#f7bd1e" d="M36 32h12v4H36zm16 0h8v4h-8zm-4 4v4h-4v4h4v4h4v-4h4v-4h-4v-4z"/><path fill="#e23f28" d="M48 40h4v4h-4z"/>', // 16: Tiara
        '<path fill="black" d="M44 88v-4h-4v-4h-4v8h4v4h8v-4z"/>', // 17: Choker
        "", "", "" // 18-20: Empty
    ];

    // ============ Accessory Layer 2 (85% none, 5% each) ============
    string[] private accessoriesLayer2 = [
        "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", // 0-17: None
        '<path fill="purple" opacity="0.6" d="M56 48h8v8h-4v-4h-4zm-20 0h8v8h-4v-4h-4z"/>', // 18: Shadow
        '<path fill="orange" d="M40 44h-4v16h4v-4h4v-8h-4zm20 4v-4h-4v16h4v-4h4v-8z"/><path fill="orange" opacity=".25" d="M60 52h4v4h-4zM40 52h4v4h-4z"/><path fill="orange" opacity=".05" d="M60 48h-4v4h8v-4zM36 48v4h8v-4h-4z"/>', // 19: Clown Eyes
        '<path fill="red" d="M48 60h8v8h-8z"/>', // 20: Clown Nose
        '<path fill="red" d="M48 64h4v4h-4z"/>' // 21: Small Nose
    ];

    // ============ Accessory Layer 3 (70% none, earrings, pipe & mask) ============
    string[] private accessoriesLayer3 = [
        "", "", "", "", "", "", "", "", "", "", "", "", // 0-11: None
        '<path fill="gold" d="M40 28h4v4h-4z"/>', // 12: Left Earring
        '<path fill="gold" d="M56 28h4v4h-4z"/>', // 13: Right Earring
        '<path fill="gold" d="M40 28h4v4h-4z M56 28h4v4h-4z"/>', // 14: Both Earrings
        '<path fill="#e0e0e0" d="M84 48v-4h-4v4h-4v8h12v-8zm-4 12h4v4h-4zm0 8h4v4h-4z"/><path fill="#0d0d0d" d="M56 72h4v4h-4zm-4 4h4v4h-4zm8 0h4v4h-4zm-4 4h4v4h-4zm8 0h4v4h-4zm-4 4h4v4h-4zm4 4h4v4h-4z"/><path fill="#0d0d0d" d="M88 76H72v8h-4v4h-4v4h4v4h16v-4h4v-4h4V76z"/><path fill="#935e26" d="M76 80v8h-8v4h16v-4h4v-8z"/><path fill="#0d0d0d" opacity=".25" d="M76 84h4v4h-4zm8 0h4v4h-4zm-4 4h4v4h-4z"/><path fill="#935e26" d="M56 76h4v4h-4zm4 4h4v4h-4zm4 4h4v4h-4z"/>', // 15: Pipe
        '<path fill="#c9cacc" d="M36 60h24v12h4v4h-4v4h-4v4H40v-4h-4v-4h-4v-4h4zm-8-8h4v4h-4zm4 4h4v4h-4zm28 0h4v4h-4z"/><path style="opacity:.1;fill:#040404" d="M48 60h4v4h-4zm-12 8h4v4h-4zm20 0h4v4h-4z"/>' // 16: Medical Mask
    ];

    // ============ Headwear (60% styled, 40% none) ============
    string[] private headwear = [
        '<path fill="black" d="M72 40v-4h-4V16h-4v-4H32v4h-4v20h-4v4h-4v4h56v-4z"/><path class="ht" d="M28 28h40v4H28z"/>',
        '<path fill="saddlebrown" d="M80 28v4H64V20h-4v-4h-8v4h-8v-4h-8v4h-4v12H16v-4h-4v8h4v4h64v-4h4v-8h-4z"/><path class="ht t50" d="M32 32h36v4H28v-4h4z"/>',
        '<path fill="black" d="M80 56V44h-4V32h-4v-4h-4v-4h-4v-4h-4v-4H36v4h-4v4h-4v4h-4v4h-4v12h-4v12h-4v20h4v8h4v12h12V40h4v-4h28v44h-4v4H44v12h20v-4h4v-4h4v-4h4v-4h4v-4h4V56z"/><path class="ht" d="M24 84h4v12h-4zm24 8h4v4h-4zm20-52v-4h-8v-4H36v4h-4v4h-4v8h-4v8h-4V44h4V32h4v-4h4v-4h4v-4h24v4h4v4h4v4h4v12h4v12h-4v-8h-4v-8zm8 16h4v20h-4zM52 88h12v4H52zm20-12h4v4h-4zm-4 4h4v4h-4zm-4 4h4v4h-4zM16 56h4v20h-4zm4 20h4v8h-4z"/>',
        '<path class="ht" d="M36 20h28v4h4v8h12v4h4v4H28V28h4v-4h4v-4z"/>',
        '<path class="ht" d="M64 28v-4h-4v-4H36v4h-4v4h-4v16h-4v16h4v24h4V44h32v40h4V28z"/>',
        '<path d="M68 32v-4h-4v-4h-4v-4H36v4h-4v4h-4v4h-4v8h48v-8z"/><path fill="#e02129" d="M64 32v-4h-4v-4H36v4h-4v4h-4v8h40v-8z"/><path style="opacity:.2" d="M28 32v8h4v-4h4v4h4v-4h4v4h4v-4h4v4h4v-4h4v-4z"/>',
        '<path d="M72 76V36h-4v-8h-4v-4h-4v-8h-4v-4h-4V8h-8v4h-4v4h-4v8h-4v4h-4v8h-4v40h-4v4h4v4h4v4h4v-8h4v-4h-4V44h4v-4h24v4h4v32h-4v4h4v4h4v-4h4v-4z"/><path class="ht" d="M68 76V36h-4v-8h-4v-4h-4v-8h-4v-4h-8v4h-4v8h-4v4h-4v8h-4v40h-4v4h4v4h4v-4h4v-4h-4V44h4v-4h24v4h4v32h-4v4h4v4h4v-4h4v-4z"/><path fill="olive" d="M36 28h4v4h-4zm8 0h4v4h-4zm8 0h4v4h-4zm-20 4h4v4h-4zm8 0h4v4h-4zm8 0h4v4h-4zm8 0h4v4h-4zm-28 4h4v4h-4zm32 0h4v4h-4zM44 12h4v4h-4zm-4 4h4v4h-4zm20 12h4v4h-4zm-8-8h4v4h-4zm4 4h4v4h-4zm-8-8h4v4h-4zm-4 4h4v4h-4zm-4 4h4v4h-4zm8 0h4v4h-4z"/>',
        '<path fill="#2e6b62" d="M64 40V24h-4v-4H36v4h-4v16h-4v44h4V44h32v40h4V40z"/><path fill="#030302" d="M64 40v-4H32v4h-4v12h16v-4h8v4h16V40z"/><path fill="#87ccd0" d="M32 40h12v4h-4v4h-8zm32 0v8h-8v-4h-4v-4z"/>',
        '<path class="ht" d="M64 32v-4h-4v-4H36v4h-4v4h-4v8h40v-8z"/><path fill="pink" d="M68 40v4h4v8h4v20h-4v8h-4v4h-8v-8h4V44h-8v4h-4v4h-4v-4h-4v-4h-8v4h-4v28h4v8h-8v-4h-4v-8h-4V52h4v-8h4v-4z"/>',
        '<path d="M76 60V40h-4v-4h-8v40h-4v4h-4v8h16v-4h4v-8h4V60z"/><path class="wh" d="M32 36h32v4H32z"/><path class="ht" d="M32 40h32v4H32z"/><path d="M28 32v4h-4v4h-4v20h-4v20h4v8h12V32z"/>',
        "", "", "", "", "" // Indices 10-14: No headwear
    ];
    
    // ============ Custom Errors ============
    error ArrayLengthMismatch();
    error ExceedsMaxSupply();
    error ExceedsMaxBatchSize();
    error ExceedsWalletLimit();
    error SaleNotActive();
    error InvalidQuantity();
    error InvalidRecipient();
    error IncorrectPayment();
    error NoFundsToWithdraw();
    error TransferFailed();

    // ============ Events ============
    event BatchMinted(address indexed minter, uint256 startTokenId, uint256 quantity);
    event SaleToggled(bool isActive);

    // ============ Constructor ============
    constructor(address initialOwner) ERC721A("Dunk Poge", "DUNK") Ownable(initialOwner) {}

    // ============ ERC2981 & Interface Support ============
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || 
               super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 salePrice) external view override returns (address, uint256) {
        return (owner(), (salePrice * ROYALTY_BPS) / 10000);
    }

    // ============ Admin Functions ============
    function toggleSale() external onlyOwner {
        saleActive = !saleActive;
        emit SaleToggled(saleActive);
    }

    /**
     * @notice Airdrop NFTs to multiple recipients (Owner only)
     * @dev Stores individual seeds for each token
     */
    function airdrop(address[] calldata recipients, uint256[] calldata quantities) external onlyOwner nonReentrant {
        if (recipients.length != quantities.length) revert ArrayLengthMismatch();
        if (recipients.length > MAX_AIRDROP_BATCH) revert ExceedsMaxBatchSize();
        
        uint256 totalQuantity = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] == address(0)) revert InvalidRecipient();
            totalQuantity += quantities[i];
        }
        if (totalSupply() + totalQuantity > MAX_SUPPLY) revert ExceedsMaxSupply();
        
        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 quantity = quantities[i];
            if (quantity == 0) continue;
            
            uint256 startTokenId = _nextTokenId();
            _safeMint(recipients[i], quantity);
            emit BatchMinted(recipients[i], startTokenId, quantity);
            
            // Generate base seed for this recipient's batch
            uint256 baseSeed = generateBaseSeed(startTokenId, recipients[i]);
            
            // Store individual seeds
            unchecked {
                for (uint256 j = 0; j < quantity; j++) {
                    uint256 tokenId = startTokenId + j;
                    tokenIdToSeed[tokenId] = uint256(keccak256(abi.encodePacked(baseSeed, tokenId, j)));
                }
            }
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoFundsToWithdraw();
        (bool success, ) = payable(owner()).call{value: balance}("");
        if (!success) revert TransferFailed();
    }

    // ============ View Functions ============
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function nextTokenId() public view returns (uint256) {
        return _nextTokenId();
    }

    function remainingSupply() public view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }

    function _tokenExists(uint256 tokenId) internal view returns (bool) {
        return tokenId >= _startTokenId() && tokenId < _nextTokenId();
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(string(abi.encodePacked(
                '{"name":"Dunk Poge",',
                '"description":"Dunk Poge: A 10,000 Fully On-Chain, Generative NFT Collection with Emergent Rarity",',
                '"image":"data:image/svg+xml;base64,',
                Base64.encode(bytes(buildSVG(1))),
                '","seller_fee_basis_points":500,"fee_recipient":"',
                Strings.toHexString(uint256(uint160(owner())), 20),
                '"}'
            ))))
        ));
    }
    
    function getTraitProbabilities() external pure returns (string memory) {
        return '{"note":"Intended probabilities - actual rarity is emergent based on minting","hair":{"no_hair":20,"each_style":4.44},"eyewear":{"no_eyewear":40,"each_style":5.45},"headwear":{"no_headwear":40,"each_style":6},"accessory_layer_1":{"none":45.5,"rosy_cheeks":15,"spots":14,"mole":13,"gold_chain":5,"tiara":4,"choker":3.5},"accessory_layer_2":{"none":85,"eye_shadow":5,"clown_eyes":5,"clown_nose":5},"accessory_layer_3":{"none":67,"left_earring":10,"right_earring":10,"both_earrings":5,"pipe":5,"medical_mask":3}}';
    }

    // ============ Minting Functions ============
    /**
     * @notice Public mint function
     * @dev Stores individual seeds for each token during minting
     * @param quantity Number of tokens to mint (max MAX_PER_WALLET)
     */
    function mint(uint256 quantity) public payable nonReentrant {
        if (!saleActive) revert SaleNotActive();
        if (quantity == 0) revert InvalidQuantity();
        if (_numberMinted(_msgSender()) + quantity > MAX_PER_WALLET) {
            revert ExceedsWalletLimit();
        }
        if (msg.value != PRICE * quantity) revert IncorrectPayment();
        if (totalSupply() + quantity > MAX_SUPPLY) revert ExceedsMaxSupply();

        uint256 startTokenId = _nextTokenId();
        _safeMint(_msgSender(), quantity);
        emit BatchMinted(_msgSender(), startTokenId, quantity);
        
        // Generate base seed for this batch
        uint256 baseSeed = generateBaseSeed(startTokenId, _msgSender());
        
        // Store individual seeds (computed once at mint time)
        unchecked {
            for (uint256 i = 0; i < quantity; i++) {
                uint256 tokenId = startTokenId + i;
                // Derive unique seed for each token from base seed
                tokenIdToSeed[tokenId] = uint256(keccak256(abi.encodePacked(baseSeed, tokenId, i)));
            }
        }
    }

    // ============ Optimized Seed Generation ============
    /**
     * @notice Generates base seed for a mint batch
     * @dev Individual token seeds derived from this during minting
     */
    function generateBaseSeed(uint256 startTokenId, address minter) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.prevrandao,
            block.timestamp,
            startTokenId,
            minter,
            tx.gasprice
        )));
    }

    /**
     * @notice Retrieves seed for a specific token
     * @dev Seeds are stored during minting, simple lookup
     */
    function getSeedForToken(uint256 tokenId) internal view returns (uint256) {
        uint256 seed = tokenIdToSeed[tokenId];
        require(seed != 0, "Seed not found");
        return seed;
    }

    // ============ Trait Data Structure ============
    struct TraitData {
        string eyeColor;
        string lipColors;
        string skinColor;
        uint256 hairType;
        string hairColor;
        uint256 eyewearType;
        string frameColor;
        string lensColor;
        uint256 headwearType;
        string headwearColor;
        uint256 accessoryLayer1Type;
        uint256 accessoryLayer2Type;
        uint256 accessoryLayer3Type;
    }

    // ============ FIXED: 16-bit Randomness Function ============
    function getTraitFromSeed(uint256 seed, uint256 position, uint256 maxValue) internal pure returns (uint8) {
        require(maxValue > 0, "Max value must be positive");
        // FIXED: Use 16-bit spacing instead of 8-bit to prevent overlap
        uint256 shifted = seed >> (position * 16);
        uint16 twoBytes = uint16(shifted);
        return uint8(twoBytes % maxValue);
    }

    // ============ Trait Generation Logic ============
    function getTraitData(uint256 tokenId) internal view returns (TraitData memory) {
        TraitData memory data;
        uint256 seed = getSeedForToken(tokenId);

        // FIXED: Use positions 0-9 instead of 1, 5, 11, 17, 23, 29, 37, 41, 43, 47
        // This keeps all positions within 256 bits with 16-bit spacing
        data.skinColor = face[getTraitFromSeed(seed, 0, face.length)];
        data.eyeColor = eyeColor[getTraitFromSeed(seed, 1, eyeColor.length)];
        data.lipColors = lipColors[getTraitFromSeed(seed, 2, lipColors.length)];
        
        // Hair (80% styled, 20% none)
        uint256 hairSeed = uint256(keccak256(abi.encodePacked(seed, uint256(200))));
        uint256 hairRand = hairSeed % 100;
        if (hairRand < 80) {
            data.hairType = getTraitFromSeed(seed, 3, 18);
        } else {
            data.hairType = 18 + (hairSeed % 5);
        }
        data.hairColor = hairColors[getTraitFromSeed(seed, 4, hairColors.length)];
        
        // Eyewear (60% styled, 40% none)
        uint256 eyewearSeed = uint256(keccak256(abi.encodePacked(seed, uint256(100))));
        uint256 eyewearRand = eyewearSeed % 100;
        if (eyewearRand < 60) {
            data.eyewearType = getTraitFromSeed(seed, 5, 11);
        } else {
            data.eyewearType = 11 + (eyewearSeed % 5);
        }
        data.frameColor = frameColors[getTraitFromSeed(seed, 6, frameColors.length)];
        data.lensColor = lensColors[getTraitFromSeed(seed, 7, lensColors.length)];
        
        // Headwear (60% styled, 40% none)
        uint256 headwearSeed = uint256(keccak256(abi.encodePacked(seed, uint256(300))));
        uint256 headwearRand = headwearSeed % 100;
        if (headwearRand < 60) {
            data.headwearType = getTraitFromSeed(seed, 8, 10);
        } else {
            data.headwearType = 10 + (headwearSeed % 5);
        }
        data.headwearColor = headwearColors[getTraitFromSeed(seed, 9, headwearColors.length)];
        
        // Accessory Layer 1 (weighted distribution - no mask)
        uint256 accSeed1 = uint256(keccak256(abi.encodePacked(seed, uint256(1))));
        uint256 rand1 = accSeed1 % 1000;
        if (rand1 < 455) data.accessoryLayer1Type = 0;       // None: 45.5%
        else if (rand1 < 605) data.accessoryLayer1Type = 12; // Rosy: 15%
        else if (rand1 < 745) data.accessoryLayer1Type = 13; // Spots: 14%
        else if (rand1 < 875) data.accessoryLayer1Type = 14; // Mole: 13%
        else if (rand1 < 925) data.accessoryLayer1Type = 15; // Chain: 5%
        else if (rand1 < 965) data.accessoryLayer1Type = 16; // Tiara: 4%
        else data.accessoryLayer1Type = 17;                  // Choker: 3.5%
        
        // Accessory Layer 2 (85% none, 5% each)
        uint256 accSeed2 = uint256(keccak256(abi.encodePacked(seed, uint256(2))));
        uint256 rand2 = accSeed2 % 100;
        if (rand2 < 85) data.accessoryLayer2Type = 0;
        else if (rand2 < 90) data.accessoryLayer2Type = 18;
        else if (rand2 < 95) data.accessoryLayer2Type = 19;
        else data.accessoryLayer2Type = 20;
        
        // Accessory Layer 3 (67% none, earrings, pipe & mask)
        uint256 accSeed3 = uint256(keccak256(abi.encodePacked(seed, uint256(3))));
        uint256 rand3 = accSeed3 % 100;
        if (rand3 < 67) data.accessoryLayer3Type = 0;        // None: 67%
        else if (rand3 < 77) data.accessoryLayer3Type = 12;  // Left Earring: 10%
        else if (rand3 < 87) data.accessoryLayer3Type = 13;  // Right Earring: 10%
        else if (rand3 < 92) data.accessoryLayer3Type = 14;  // Both Earrings: 5%
        else if (rand3 < 97) data.accessoryLayer3Type = 15;  // Pipe: 5%
        else data.accessoryLayer3Type = 16;                  // Medical Mask: 3%
        
        // Visual compatibility: Pilot helmet forces no eyewear
        if (data.headwearType == 7) {
            data.eyewearType = 11;
        }

        return data;
    }

    // ============ TokenURI & Metadata ============
    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (!_tokenExists(tokenId)) revert URIQueryForNonexistentToken();
        
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(string(abi.encodePacked(
                '{"name":"Dunk Poge #', tokenId.toString(),
                '","description":"Dunk Poge: A 10,000 Fully On-Chain, Generative NFT Collection with Emergent Rarity","image":"data:image/svg+xml;base64,',
                Base64.encode(bytes(buildSVG(tokenId))),
                '",', buildAttributes(tokenId), '}'
            ))))
        ));
    }

    // ============ CSS Generation ============
    function buildCSS(TraitData memory data) internal pure returns (string memory) {
        string memory part1 = string(abi.encodePacked(
            "<defs><style>.fr{fill:", data.frameColor,
            ";}.gl{fill:", data.lensColor,
            ";}.ht{fill:", data.headwearColor,
            ";}.hr{fill:", data.hairColor,
            ";}.sk{fill:", data.skinColor, ";}"
        ));

        string memory part2 = string(abi.encodePacked(
            ".br{fill:", data.hairColor,
            ";filter:brightness(0.6);}.pl{fill:", data.eyeColor,
            ";}.lip{fill:", data.lipColors,
            ";}.nose{fill:black;opacity:.75;}.wh{fill:white;}.t0{opacity:0;}.t25{opacity:.25;}.t50{opacity:.5;}.t75{opacity:.75;}</style></defs>"
        ));
        return string(abi.encodePacked(part1, part2));
    }

    // ============ SVG Building ============
    function getFaceSVG(string memory skinColor) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<path fill="',skinColor,
                '" d="M60 32v-4h-4v4h-4v4h-4v-4h-4v-4h-4v4h-4v4h-4v40h4v20h12v-8h-4v-4h12v-4h4v-4h4V32z"/>'
            )
        );
    }

    function buildSVG(uint256 tokenId) internal view returns (string memory) {
        TraitData memory data = getTraitData(tokenId);
        string memory css = buildCSS(data);

        string memory part1 = string(abi.encodePacked(
            svgStart,
            css,
            svgBackground,
            getFaceSVG(data.skinColor),
            '<path d="M44 72h12v4H44z" class="lip"/>',
            '<path d="M48 64h4v4h-4z" class="nose"/>',
            accessoriesLayer1[data.accessoryLayer1Type],
            '<path d="M36 48h8v4h-8zm20 0h8v4h-8z" class="br t50"/>',
            accessoriesLayer2[data.accessoryLayer2Type],
            eyes
        ));
        
        string memory part2 = string(abi.encodePacked(
            hair[data.hairType],
            headwear[data.headwearType],
            dogeear,
            eyewear[data.eyewearType],
            accessoriesLayer3[data.accessoryLayer3Type]
        ));
        
        return string(abi.encodePacked(part1, part2, "</svg>"));
    }

    // ============ Attribute Building ============
    function buildAttributes(uint256 tokenId) internal view returns (string memory) {
        TraitData memory data = getTraitData(tokenId);
        string memory required = string(abi.encodePacked(
            '{"trait_type":"Skin","value":"', data.skinColor,
            '"},{"trait_type":"Eye Color","value":"', data.eyeColor,
            '"},{"trait_type":"Lip Color","value":"', data.lipColors, '"}'
        ));
        string memory optional = buildOptionalTraits(data);
        return string(abi.encodePacked('"attributes":[', required, optional, "]"));
    }

    function buildOptionalTraits(TraitData memory data) internal pure returns (string memory) {
        string memory result = "";
        
        string memory hairName = getHairName(data.hairType, data.hairColor);
        result = string(abi.encodePacked(result, ',{"trait_type":"Hair","value":"', hairName, '"}'));

        string memory eyewearName = getEyewearName(data.eyewearType, data.frameColor, data.lensColor);
        result = string(abi.encodePacked(result, ',{"trait_type":"Eyewear","value":"', eyewearName, '"}'));

        string memory headwearName = getHeadwearName(data.headwearType, data.headwearColor);
        result = string(abi.encodePacked(result, ',{"trait_type":"Headwear","value":"', headwearName, '"}'));

        result = string(abi.encodePacked(result, buildAccessoryTraits(data)));
        return result;
    }

    function buildAccessoryTraits(TraitData memory data) internal pure returns (string memory) {
        string memory result = "";
        string memory acc1Name = getAccessoryLayer1Name(data.accessoryLayer1Type);
        result = string(abi.encodePacked(result, ',{"trait_type":"Accessory Layer 1","value":"', acc1Name, '"}'));

        string memory acc2Name = getAccessoryLayer2Name(data.accessoryLayer2Type);
        result = string(abi.encodePacked(result, ',{"trait_type":"Accessory Layer 2","value":"', acc2Name, '"}'));

        string memory acc3Name = getAccessoryLayer3Name(data.accessoryLayer3Type);
        result = string(abi.encodePacked(result, ',{"trait_type":"Accessory Layer 3","value":"', acc3Name, '"}'));

        return result;
    }

    // ============ Trait Name Helpers ============
    function getHeadwearName(uint256 t, string memory c) internal pure returns (string memory) {
        if (t == 0) return string(abi.encodePacked("Top Hat ", c));
        if (t == 1) return string(abi.encodePacked("Cowboy Hat ", c));
        if (t == 2) return string(abi.encodePacked("Hoodie ", c));
        if (t == 3) return string(abi.encodePacked("Cap ", c));
        if (t == 4) return string(abi.encodePacked("Helmet ", c));
        if (t == 5) return string(abi.encodePacked("Knitted Cap ", c));
        if (t == 6) return string(abi.encodePacked("Tassle Hat ", c));
        if (t == 7) return string(abi.encodePacked("Pilot Helmet "));
        if (t == 8) return string(abi.encodePacked("Pink wif Hat ", c));
        if (t == 9) return string(abi.encodePacked("Headband ", c));
        if (t >= 10 && t <= 14) return "None";
        return "";
    }

    function getHairName(uint256 t, string memory c) internal pure returns (string memory) {
        if (t == 0) return string(abi.encodePacked("Stringy Hair ", c));
        if (t == 1) return string(abi.encodePacked("Wild Hair ", c));
        if (t == 2) return string(abi.encodePacked("Wilder Hair ", c));
        if (t == 3) return string(abi.encodePacked("Wildest Hair ", c));
        if (t == 4) return string(abi.encodePacked("Frumpy Hair ", c));
        if (t == 5) return string(abi.encodePacked("Messy Hair ", c));
        if (t == 6) return string(abi.encodePacked("Side Hair ", c));
        if (t == 7) return string(abi.encodePacked("Crazy Hair ", c));
        if (t == 8) return string(abi.encodePacked("Mohawk ", c));
        if (t == 9) return string(abi.encodePacked("Mohawk Thin ", c));
        if (t == 10) return string(abi.encodePacked("Tiny Mohawk ", c));
        if (t == 11) return string(abi.encodePacked("Half Shaved ", c));
        if (t == 12) return string(abi.encodePacked("Straight Hair ", c));
        if (t == 13) return string(abi.encodePacked("Pigtails ", c));
        if (t == 14) return string(abi.encodePacked("Bob Hair ", c));
        if (t == 15) return string(abi.encodePacked("Plain Hair ", c));
        if (t == 16) return string(abi.encodePacked("Short Hair ", c));
        if (t == 17) return string(abi.encodePacked("Clown Hair ", c));
        if (t >= 18 && t <= 22) return "None";
        return "";
    }

    function getEyewearName(uint256 t, string memory f, string memory l) internal pure returns (string memory) {
        if (t == 0) return string(abi.encodePacked("Nerd Glasses ", f, "/", l));
        if (t == 1) return string(abi.encodePacked("Horn Rimmed ", f, "/", l));
        if (t == 2) return string(abi.encodePacked("Classic Shades ", f));
        if (t == 3) return string(abi.encodePacked("Eye Patch ", f));
        if (t == 4) return string(abi.encodePacked("Regular Shades ", f));
        if (t == 5) return "3D Glasses";
        if (t == 6) return string(abi.encodePacked("VR Headset ", f));
        if (t == 7) return string(abi.encodePacked("Big Shades ", f, "/", l));
        if (t == 8) return string(abi.encodePacked("Welding Goggles ", f, "/", l));
        if (t == 9) return string(abi.encodePacked("Eye Mask ", f));
        if (t == 10) return string(abi.encodePacked("Small Shades ", f));
        if (t >= 11 && t <= 15) return "None";
        return "";
    }

    function getAccessoryLayer1Name(uint256 t) internal pure returns (string memory) {
        if (t == 12) return "Rosy Cheeks";
        if (t == 13) return "Spots";
        if (t == 14) return "Mole";
        if (t == 15) return "Gold Chain";
        if (t == 16) return "Tiara";
        if (t == 17) return "Choker";
        return "None";
    }

    function getAccessoryLayer2Name(uint256 t) internal pure returns (string memory) {
        if (t == 18) return "Eye Shadow";
        if (t == 19) return "Clown Eyes";
        if (t == 20) return "Clown Nose";
        return "None";
    }

    function getAccessoryLayer3Name(uint256 t) internal pure returns (string memory) {
        if (t == 12) return "Left Earring";
        if (t == 13) return "Right Earring"; 
        if (t == 14) return "Earrings";
        if (t == 15) return "Pipe";
        if (t == 16) return "Medical Mask";
        return "None";
    }
}
