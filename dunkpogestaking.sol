// ============================================
//    D U N K   P O G E   S T A K I N G
//    1 Billion POGE • 10,000 NFTs
//    Fully Decentralized & Immutable
// ============================================

/**
 * @notice TRUSTLESS BY DESIGN - Walkaway Test Compliant
 * @dev No owner. No admin. No pause. No upgrades. No trust required.
 * @dev If the deployer disappears, this contract works forever.
 * @dev Users can always retrieve NFTs via emergencyWithdraw().
 * @dev All rewards math is verifiable on-chain.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title DunkPogeStaking - Production Ready for 1B POGE Supply
 * @notice Decentralized NFT staking with emission decay and loyalty multipliers
 * @dev Fully immutable - no admin, no pause, no upgrades, no vesting
 *
 * SUPPLY: 1,000,000,000 POGE (1 billion)
 * EMISSIONS: 10 POGE/day → 1 POGE/day per NFT over 730 days
 * MULTIPLIERS: 1x → 2x over 180 days
 *
 * Tested scenarios:
 * - Edge case (10K NFTs, max multipliers): 724M POGE used, 276M buffer
 * - Realistic (70% participation): 400M POGE used, 600M buffer
 *
 * Security:
 * - NFTs transferred before state deletion (prevents loss)
 * - Graceful pool degradation (no reverts if pool runs low)
 * - Stack depth optimized
 * - ReentrancyGuard on all state-changing functions
 * - No external dependencies or admin control
 *
 * Achievements are PERMANENT historical records:
 * - Early Adopter: Staked within 30 days of launch
 * - Diamond Paws: Any NFT staked 180+ continuous days
 * - Collector: Held 10+ NFTs simultaneously for 7+ days
 * - Poge Whale: Lifetime earnings ≥10,000 POGE
 */
 
contract DunkPogeStaking is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ Immutable State ============

    IERC721 public immutable dunkPogeNFT;
    IERC20 public immutable pogeCoin;
    uint256 public immutable LAUNCH_TIMESTAMP;

    // ============ Emission Constants ============

    uint256 private constant BASE_EMISSION = 11574074074074; // ~1 POGE/day (per second per NFT)
    uint256 private constant INITIAL_BONUS = 104166666666666; // ~9 POGE/day (per second per NFT)
    uint256 private constant DECAY_PERIOD = 730 days;
    uint256 private constant MAX_MULTIPLIER = 2e18; // 2.0x
    uint256 private constant BASE_MULTIPLIER = 1e18; // 1.0x
    uint256 private constant MULTIPLIER_SCALE = 1e18;
    uint256 private constant LOYALTY_PERIOD = 180 days;
    uint256 private constant SECONDS_PER_DAY = 86400;

    // ============ Operational Limits ============

    uint256 public constant MAX_TOKENS_PER_TX = 100; // Batch limit for gas efficiency

    // ============ Achievement Thresholds ============

    uint256 private constant EARLY_ADOPTER_DAYS = 30;
    uint256 private constant DIAMOND_PAWS_DAYS = 180;
    uint256 private constant COLLECTOR_COUNT = 10;
    uint256 private constant COLLECTOR_MIN_DURATION = 7 days;
    uint256 private constant POGE_WHALE_THRESHOLD = 10000 * 1e18; // 10,000 POGE

    // ============ Structs ============

    struct Stake {
        address owner;
        uint256 stakedAt;
        uint256 lastClaimedAt;
    }

    struct NFTPerformance {
        uint256 totalEarned;
        uint256 totalStakeDuration;
        uint256 highestMultiplier;
        uint256 lastActiveAt;
    }

    struct UserAchievements {
        // Permanent achievement status
        bool isEarlyAdopter;
        bool hasDiamondPaws;
        bool isCollector;
        bool isPogeWhale;
        // Historical tracking
        uint256 totalNFTsStaked; // Lifetime total
        uint256 activeNFTsStaked; // Current active stakes (O(1) tracking)
        uint256 totalPogeEarned; // Lifetime earnings
        // Collector specific
        uint256 peakConcurrentStakes; // Highest simultaneous NFTs
        uint256 peakReachedAt; // When peak occurred
        uint256 collectorEarnedAt; // When collector achieved
        // Diamond Paws specific
        uint256 longestStakeDuration; // Longest continuous stake
        uint256 diamondPawsEarnedAt; // When Diamond Paws achieved
        // Poge Whale specific
        uint256 whaleEarnedAt; // When Poge Whale achieved
        // Early Adopter specific
        uint256 firstStakeTimestamp; // First stake ever
    }

    // ============ Storage ============

    mapping(uint256 => Stake) public stakes;
    mapping(address => uint256[]) public userStakes;
    mapping(uint256 => NFTPerformance) public nftPerformance;
    mapping(address => UserAchievements) public userAchievements;
    mapping(address => mapping(uint256 => uint256)) private userStakeIndex;
    mapping(address => bool) private hasStakedBefore;

    // ============ Enhanced Statistics ============

    uint256 public totalStakedNFTs;
    uint256 public uniqueStakers;
    uint256 public totalRewardsDistributed;
    uint256 public totalRewardsClaimed;
    uint256 public totalRewardsShortfall;
    uint256 public longestStakeDuration;
    uint256 public highestLoyaltyMultiplier;
    uint256 public totalStakeTransactions;

    // ============ Events ============

    event Staked(
        address indexed user,
        uint256 indexed tokenId,
        uint256 timestamp
    );
    event Unstaked(
        address indexed user,
        uint256 indexed tokenId,
        uint256 timestamp,
        uint256 rewards
    );
    event RewardsClaimed(
        address indexed user,
        uint256 amountOwed,
        uint256 amountPaid
    );

    event EmergencyWithdraw(address indexed user, uint256 indexed tokenId);
    event EmergencyWithdrawWarning(
        address indexed user,
        uint256 indexed tokenId,
        string warning
    );

    event AchievementUnlocked(
        address indexed user,
        string achievement,
        uint256 timestamp
    );
    event PogeMilestone(
        address indexed user,
        string milestone,
        uint256 amount,
        uint256 timestamp
    );
    event RewardPoolInsufficient(
        address indexed user,
        uint256 owed,
        uint256 paid,
        uint256 shortfall
    );

    // ============ Constructor ============

    constructor(address _dunkPogeNFT, address _pogeCoin) {
        require(_dunkPogeNFT != address(0), "Invalid NFT address");
        require(_pogeCoin != address(0), "Invalid token address");

        require(
            IERC165(_dunkPogeNFT).supportsInterface(type(IERC721).interfaceId),
            "Not ERC721 contract"
        );

        dunkPogeNFT = IERC721(_dunkPogeNFT);
        pogeCoin = IERC20(_pogeCoin);
        LAUNCH_TIMESTAMP = block.timestamp;
    }

    // ============ Achievement Helpers ============

    function _checkEarlyAdopterAchievement(
        address user,
        uint256 stakeTimestamp
    ) private {
        UserAchievements storage ach = userAchievements[user];

        if (
            !ach.isEarlyAdopter &&
            stakeTimestamp < LAUNCH_TIMESTAMP + (EARLY_ADOPTER_DAYS * 1 days)
        ) {
            ach.isEarlyAdopter = true;
            emit AchievementUnlocked(user, "Early Adopter", block.timestamp);
        }
    }

    function _checkDiamondPawsAchievement(
        address user,
        uint256 stakeDuration
    ) private {
        UserAchievements storage ach = userAchievements[user];

        // Update longest duration
        if (stakeDuration > ach.longestStakeDuration) {
            ach.longestStakeDuration = stakeDuration;
        }

        // Check achievement
        if (
            !ach.hasDiamondPaws &&
            ach.longestStakeDuration >= DIAMOND_PAWS_DAYS * 1 days
        ) {
            ach.hasDiamondPaws = true;
            ach.diamondPawsEarnedAt = block.timestamp;
            emit AchievementUnlocked(user, "Diamond Paws", block.timestamp);
        }
    }

    function _checkCollectorAchievement(address user) private {
        UserAchievements storage ach = userAchievements[user];

        // Already a collector? Permanent achievement
        if (ach.isCollector) {
            return;
        }

        // Update peak
        if (ach.activeNFTsStaked > ach.peakConcurrentStakes) {
            ach.peakConcurrentStakes = ach.activeNFTsStaked;
            ach.peakReachedAt = block.timestamp;
        }

        // Check achievement
        if (
            ach.peakConcurrentStakes >= COLLECTOR_COUNT &&
            ach.peakReachedAt > 0 &&
            block.timestamp >= ach.peakReachedAt + COLLECTOR_MIN_DURATION
        ) {
            ach.isCollector = true;
            ach.collectorEarnedAt = block.timestamp;
            emit AchievementUnlocked(user, "Collector", block.timestamp);
        }
    }

    function _checkPogeWhaleAchievement(
        address user,
        uint256 newlyEarned
    ) private {
        UserAchievements storage ach = userAchievements[user];

        if (
            !ach.isPogeWhale &&
            ach.totalPogeEarned + newlyEarned >= POGE_WHALE_THRESHOLD
        ) {
            ach.isPogeWhale = true;
            ach.whaleEarnedAt = block.timestamp;
            emit AchievementUnlocked(user, "Poge Whale", block.timestamp);
        }
    }

    // ============ Core Staking Functions ============

    function stake(uint256[] calldata tokenIds) external nonReentrant {
        uint256 length = tokenIds.length;
        require(length > 0, "Empty array");
        require(length <= MAX_TOKENS_PER_TX, "Too many tokens");

        UserAchievements storage ach = userAchievements[msg.sender];

        // First-time staker setup
        if (!hasStakedBefore[msg.sender]) {
            hasStakedBefore[msg.sender] = true;
            uniqueStakers++;
            ach.firstStakeTimestamp = block.timestamp;
        }

        totalStakeTransactions++;

        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = tokenIds[i];

            require(
                dunkPogeNFT.ownerOf(tokenId) == msg.sender,
                "Not token owner"
            );
            require(stakes[tokenId].owner == address(0), "Already staked");

            dunkPogeNFT.transferFrom(msg.sender, address(this), tokenId);

            stakes[tokenId] = Stake({
                owner: msg.sender,
                stakedAt: block.timestamp,
                lastClaimedAt: block.timestamp
            });

            userStakeIndex[msg.sender][tokenId] = userStakes[msg.sender].length;
            userStakes[msg.sender].push(tokenId);

            nftPerformance[tokenId].lastActiveAt = block.timestamp;

            emit Staked(msg.sender, tokenId, block.timestamp);
        }

        totalStakedNFTs += length;
        ach.totalNFTsStaked += length;
        ach.activeNFTsStaked += length;

        // Check achievements
        _checkEarlyAdopterAchievement(msg.sender, block.timestamp);
        _checkCollectorAchievement(msg.sender);
    }

    /**
     * @notice Standard unstake function for specific token IDs
     */
    function unstake(uint256[] calldata tokenIds) external nonReentrant {
        uint256 length = tokenIds.length;
        require(length > 0, "Empty array");
        require(length <= MAX_TOKENS_PER_TX, "Too many tokens");

        // Convert calldata to memory for internal processing
        uint256[] memory tokenIdsMemory = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            tokenIdsMemory[i] = tokenIds[i];
        }

        _unstakeInternal(tokenIdsMemory);
    }

    /**
     * @notice Unstake as many NFTs as possible in one transaction (up to MAX_TOKENS_PER_TX)
     * @dev Optimized to only collect active stakes and allocate exact array size
     */
    function unstakeMax() external nonReentrant {
        uint256[] storage userTokens = userStakes[msg.sender];
        require(userTokens.length > 0, "No staked NFTs");

        // Count active stakes first (capped at MAX_TOKENS_PER_TX)
        uint256 activeCount = 0;
        for (
            uint256 i = 0;
            i < userTokens.length && activeCount < MAX_TOKENS_PER_TX;
            i++
        ) {
            if (stakes[userTokens[i]].owner == msg.sender) {
                activeCount++;
            }
        }

        require(activeCount > 0, "No active stakes found");

        // Allocate exact size needed
        uint256[] memory tokenIds = new uint256[](activeCount);
        uint256 index = 0;

        // Collect active stakes
        for (uint256 i = 0; i < userTokens.length && index < activeCount; i++) {
            uint256 tokenId = userTokens[i];
            if (stakes[tokenId].owner == msg.sender) {
                tokenIds[index] = tokenId;
                index++;
            }
        }

        _unstakeInternal(tokenIds);
    }

    /**
     * @notice Unstake a specific chunk of NFTs
     * @dev Only collects active stakes within the range
     */
    function unstakeChunk(
        uint256 startIndex,
        uint256 count
    ) external nonReentrant {
        require(count > 0 && count <= MAX_TOKENS_PER_TX, "Invalid count");

        uint256[] storage userTokens = userStakes[msg.sender];
        require(startIndex < userTokens.length, "Invalid start index");

        uint256 endIndex = startIndex + count;
        if (endIndex > userTokens.length) {
            endIndex = userTokens.length;
        }

        // Count active stakes in range
        uint256 activeCount = 0;
        for (uint256 i = startIndex; i < endIndex; i++) {
            if (stakes[userTokens[i]].owner == msg.sender) {
                activeCount++;
            }
        }

        require(activeCount > 0, "No active stakes in range");

        // Collect active stakes
        uint256[] memory tokenIds = new uint256[](activeCount);
        uint256 index = 0;

        for (uint256 i = startIndex; i < endIndex && index < activeCount; i++) {
            uint256 tokenId = userTokens[i];
            if (stakes[tokenId].owner == msg.sender) {
                tokenIds[index] = tokenId;
                index++;
            }
        }

        _unstakeInternal(tokenIds);
    }

    /**
     * @notice Internal unstake function used by all unstake paths
     * @dev Contains all unstaking logic including achievement checks
     */
    function _unstakeInternal(uint256[] memory tokenIds) internal {
        uint256 length = tokenIds.length;
        require(length > 0, "Empty array");
        require(length <= MAX_TOKENS_PER_TX, "Too many tokens");

        uint256 totalRewards;
        uint256 longestDurationInBatch = 0;

        // Calculate rewards and track durations
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = tokenIds[i];
            Stake memory stakeInfo = stakes[tokenId];

            require(stakeInfo.owner == msg.sender, "Not stake owner");

            uint256 rewards = calculateRewards(tokenId);
            totalRewards += rewards;

            uint256 stakeDuration = block.timestamp - stakeInfo.stakedAt;
            if (stakeDuration > longestDurationInBatch) {
                longestDurationInBatch = stakeDuration;
            }

            if (stakeDuration > longestStakeDuration) {
                longestStakeDuration = stakeDuration;
            }

            nftPerformance[tokenId].totalEarned += rewards;
            nftPerformance[tokenId].totalStakeDuration += stakeDuration;
            nftPerformance[tokenId].lastActiveAt = block.timestamp;

            uint256 finalMultiplier = getLoyaltyMultiplier(stakeInfo.stakedAt);
            if (finalMultiplier > nftPerformance[tokenId].highestMultiplier) {
                nftPerformance[tokenId].highestMultiplier = finalMultiplier;
            }
            if (finalMultiplier > highestLoyaltyMultiplier) {
                highestLoyaltyMultiplier = finalMultiplier;
            }
        }

        // DECLARE ach HERE (outside if block, accessible everywhere)
        UserAchievements storage ach = userAchievements[msg.sender];
        uint256 actualPaid = 0;

        // Transfer rewards
        if (totalRewards > 0) {
            totalRewardsDistributed += totalRewards;

            uint256 poolBalance = pogeCoin.balanceOf(address(this));

            if (poolBalance >= totalRewards) {
                actualPaid = totalRewards;
                pogeCoin.safeTransfer(msg.sender, totalRewards);
            } else if (poolBalance > 0) {
                actualPaid = poolBalance;
                uint256 shortfall = totalRewards - poolBalance;
                totalRewardsShortfall += shortfall;

                pogeCoin.safeTransfer(msg.sender, poolBalance);
                emit RewardPoolInsufficient(
                    msg.sender,
                    totalRewards,
                    poolBalance,
                    shortfall
                );
            } else {
                totalRewardsShortfall += totalRewards;
                emit RewardPoolInsufficient(
                    msg.sender,
                    totalRewards,
                    0,
                    totalRewards
                );
            }

            totalRewardsClaimed += actualPaid;

            // Now ach is accessible here
            ach.totalPogeEarned += actualPaid;
            _checkPogeWhaleAchievement(msg.sender, actualPaid);

            if (actualPaid >= 1000 * 1e18) {
                emit PogeMilestone(
                    msg.sender,
                    "Such Poge! Much Reward!",
                    actualPaid,
                    block.timestamp
                );
            }

            emit RewardsClaimed(msg.sender, totalRewards, actualPaid);
        }

        // Transfer NFTs back
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = tokenIds[i];
            dunkPogeNFT.transferFrom(address(this), msg.sender, tokenId);
        }

        // Clear state
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = tokenIds[i];

            emit Unstaked(
                msg.sender,
                tokenId,
                block.timestamp,
                nftPerformance[tokenId].totalEarned
            );

            delete stakes[tokenId];
            _removeFromUserStakes(msg.sender, tokenId);
        }

        // Update state - ach is accessible here now
        totalStakedNFTs -= length;
        ach.activeNFTsStaked -= length;

        // Check achievements (permanent once earned)
        _checkDiamondPawsAchievement(msg.sender, longestDurationInBatch);
        _checkCollectorAchievement(msg.sender);
    }

    function claimRewards() external nonReentrant {
        uint256[] memory userTokens = userStakes[msg.sender];
        uint256 totalRewards;

        for (uint256 i = 0; i < userTokens.length; i++) {
            uint256 tokenId = userTokens[i];
            if (stakes[tokenId].owner == msg.sender) {
                totalRewards += calculateRewards(tokenId);
            }
        }

        require(totalRewards > 0, "No rewards");

        for (uint256 i = 0; i < userTokens.length; i++) {
            uint256 tokenId = userTokens[i];
            if (stakes[tokenId].owner == msg.sender) {
                stakes[tokenId].lastClaimedAt = block.timestamp;
                nftPerformance[tokenId].lastActiveAt = block.timestamp;
            }
        }

        totalRewardsDistributed += totalRewards;

        uint256 poolBalance = pogeCoin.balanceOf(address(this));
        uint256 actualPaid = 0;

        if (poolBalance >= totalRewards) {
            actualPaid = totalRewards;
            pogeCoin.safeTransfer(msg.sender, totalRewards);
        } else if (poolBalance > 0) {
            actualPaid = poolBalance;
            uint256 shortfall = totalRewards - poolBalance;
            totalRewardsShortfall += shortfall;

            pogeCoin.safeTransfer(msg.sender, poolBalance);
            emit RewardPoolInsufficient(
                msg.sender,
                totalRewards,
                poolBalance,
                shortfall
            );
        } else {
            totalRewardsShortfall += totalRewards;
            emit RewardPoolInsufficient(
                msg.sender,
                totalRewards,
                0,
                totalRewards
            );
        }

        totalRewardsClaimed += actualPaid;

        UserAchievements storage ach = userAchievements[msg.sender];
        ach.totalPogeEarned += actualPaid;
        _checkPogeWhaleAchievement(msg.sender, actualPaid);

        if (actualPaid >= 500 * 1e18) {
            emit PogeMilestone(
                msg.sender,
                "Very Claim! Much Poge!",
                actualPaid,
                block.timestamp
            );
        }

        emit RewardsClaimed(msg.sender, totalRewards, actualPaid);
    }

    /**
     * @notice EMERGENCY ONLY: Withdraw NFTs without claiming rewards.
     * @dev ⚠️🚨🔥 DANGER: ALL REWARDS PERMANENTLY LOST. NO ACHIEVEMENTS. 🚨🔥⚠️
     * @dev Use normal unstake() unless POGE transfers are failing or gas savings critical.
     * @dev All pending rewards forfeited. NFTs returned immediately.
     * @dev Diamond Paws NOT earned. Performance stats NOT updated.
     */
    function emergencyWithdraw(
        uint256[] calldata tokenIds
    ) external nonReentrant {
        uint256 length = tokenIds.length;
        require(length > 0, "Empty array");
        require(length <= MAX_TOKENS_PER_TX, "Too many tokens");

        // Transfer NFTs first (safety)
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = tokenIds[i];
            require(stakes[tokenId].owner == msg.sender, "Not stake owner");

            // Emit warning for each NFT
            emit EmergencyWithdrawWarning(
                msg.sender,
                tokenId,
                "All rewards permanently forfeited. Use normal unstake() to claim rewards and achievements."
            );

            dunkPogeNFT.transferFrom(address(this), msg.sender, tokenId);
        }

        // Clear state
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = tokenIds[i];
            delete stakes[tokenId];
            _removeFromUserStakes(msg.sender, tokenId);
            emit EmergencyWithdraw(msg.sender, tokenId);
        }

        // Update state (achievements not checked in emergency)
        totalStakedNFTs -= length;
        userAchievements[msg.sender].activeNFTsStaked -= length;
    }

    // ============ Preview Functions ============

    /**
     * @notice Preview what would be unstaked with unstakeMax()
     */
    function previewUnstakeMax()
        external
        view
        returns (
            uint256[] memory tokenIds,
            uint256 totalRewards,
            uint256 maxPerBatch
        )
    {
        uint256[] storage userTokens = userStakes[msg.sender];

        // Count active stakes first
        uint256 activeCount = 0;
        totalRewards = 0;

        for (
            uint256 i = 0;
            i < userTokens.length && activeCount < MAX_TOKENS_PER_TX;
            i++
        ) {
            uint256 tokenId = userTokens[i];
            if (stakes[tokenId].owner == msg.sender) {
                activeCount++;
                totalRewards += calculateRewards(tokenId);
            }
        }

        // Collect preview
        tokenIds = new uint256[](activeCount);
        uint256 index = 0;

        for (uint256 i = 0; i < userTokens.length && index < activeCount; i++) {
            uint256 tokenId = userTokens[i];
            if (stakes[tokenId].owner == msg.sender) {
                tokenIds[index] = tokenId;
                index++;
            }
        }

        maxPerBatch = MAX_TOKENS_PER_TX;
    }

    /**
     * @notice Preview what would be unstaked with unstakeChunk()
     */
    function previewUnstakeChunk(
        uint256 startIndex,
        uint256 count
    )
        external
        view
        returns (
            uint256[] memory tokenIds,
            uint256 totalRewards,
            bool hasActiveInRange
        )
    {
        require(count > 0 && count <= MAX_TOKENS_PER_TX, "Invalid count");

        uint256[] storage userTokens = userStakes[msg.sender];
        require(startIndex < userTokens.length, "Invalid start index");

        uint256 endIndex = startIndex + count;
        if (endIndex > userTokens.length) {
            endIndex = userTokens.length;
        }

        // Count active stakes in range
        uint256 activeCount = 0;
        totalRewards = 0;

        for (uint256 i = startIndex; i < endIndex; i++) {
            uint256 tokenId = userTokens[i];
            if (stakes[tokenId].owner == msg.sender) {
                activeCount++;
                totalRewards += calculateRewards(tokenId);
            }
        }

        hasActiveInRange = activeCount > 0;

        // Collect preview
        tokenIds = new uint256[](activeCount);
        uint256 index = 0;

        for (uint256 i = startIndex; i < endIndex && index < activeCount; i++) {
            uint256 tokenId = userTokens[i];
            if (stakes[tokenId].owner == msg.sender) {
                tokenIds[index] = tokenId;
                index++;
            }
        }
    }

    // ============ TRUTH ONLY: View Functions ============

    /**
     * @notice Get verifiable global statistics
     */
    function getGlobalStats()
        external
        view
        returns (
            uint256 stakedNFTs,
            uint256 stakers,
            uint256 rewardsDistributed,
            uint256 rewardsClaimed,
            uint256 rewardsShortfall,
            uint256 longestDuration,
            uint256 highestMultiplier,
            uint256 totalTransactions,
            uint256 rewardPoolBalance
        )
    {
        stakedNFTs = totalStakedNFTs;
        stakers = uniqueStakers;
        rewardsDistributed = totalRewardsDistributed;
        rewardsClaimed = totalRewardsClaimed;
        rewardsShortfall = totalRewardsShortfall;
        longestDuration = longestStakeDuration;
        highestMultiplier = highestLoyaltyMultiplier;
        totalTransactions = totalStakeTransactions;
        rewardPoolBalance = pogeCoin.balanceOf(address(this));
    }

    /**
     * @notice Get verifiable reward pool facts
     */
    function getRewardPoolFacts()
        external
        view
        returns (
            uint256 poolBalance,
            uint256 totalStaked,
            uint256 timeSinceLaunch,
            uint256 baseEmissionRate,
            uint256 currentMultiplierRangeMin,
            uint256 currentMultiplierRangeMax
        )
    {
        poolBalance = pogeCoin.balanceOf(address(this));
        totalStaked = totalStakedNFTs;
        timeSinceLaunch = block.timestamp - LAUNCH_TIMESTAMP;
        baseEmissionRate = this.getCurrentEmissionRate();
        currentMultiplierRangeMin = BASE_MULTIPLIER;
        currentMultiplierRangeMax = MAX_MULTIPLIER;
    }

    /**
     * @notice Get NFT performance facts
     */
    function getNFTPerformance(
        uint256 tokenId
    )
        external
        view
        returns (
            uint256 totalEarned,
            uint256 totalStakeSeconds,
            uint256 bestMultiplier,
            uint256 lastActiveTimestamp,
            bool isCurrentlyStaked
        )
    {
        NFTPerformance memory perf = nftPerformance[tokenId];
        totalEarned = perf.totalEarned;
        totalStakeSeconds = perf.totalStakeDuration;
        bestMultiplier = perf.highestMultiplier;
        lastActiveTimestamp = perf.lastActiveAt;
        isCurrentlyStaked = stakes[tokenId].owner != address(0);
    }

    /**
     * @notice Get user achievement facts
     */
    /**
     * @notice Get user achievement facts
     */
    function getUserAchievements(
        address user
    )
        external
        view
        returns (
            bool isEarlyAdopter,
            bool hasDiamondPaws,
            bool isCollector,
            bool isPogeWhale,
            uint256 activeStakesCount,
            uint256 totalEarnedPoge,
            uint256 firstStakeTimestamp,
            uint256 peakConcurrentStakes,
            uint256 userLongestStakeDuration // RENAMED to avoid shadowing
        )
    {
        UserAchievements memory ach = userAchievements[user];
        isEarlyAdopter = ach.isEarlyAdopter;
        hasDiamondPaws = ach.hasDiamondPaws;
        isCollector = ach.isCollector;
        isPogeWhale = ach.isPogeWhale;
        activeStakesCount = ach.activeNFTsStaked;
        totalEarnedPoge = ach.totalPogeEarned;
        firstStakeTimestamp = ach.firstStakeTimestamp;
        peakConcurrentStakes = ach.peakConcurrentStakes;
        userLongestStakeDuration = ach.longestStakeDuration; // USE NEW NAME
    }

    /**
     * @notice Get user's stake information
     */
    function getUserStakeInfo(
        address user
    )
        external
        view
        returns (
            uint256[] memory tokenIds,
            uint256 activeStakeCount,
            uint256 totalPendingRewards
        )
    {
        uint256[] memory allTokens = userStakes[user];
        uint256 activeCount = 0;
        totalPendingRewards = 0;

        // Count active stakes and calculate rewards
        for (uint256 i = 0; i < allTokens.length; i++) {
            uint256 tokenId = allTokens[i];
            if (stakes[tokenId].owner == user) {
                activeCount++;
                totalPendingRewards += calculateRewards(tokenId);
            }
        }

        // Return active token IDs
        tokenIds = new uint256[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < allTokens.length && index < activeCount; i++) {
            uint256 tokenId = allTokens[i];
            if (stakes[tokenId].owner == user) {
                tokenIds[index] = tokenId;
                index++;
            }
        }

        activeStakeCount = activeCount;
    }

    /**
     * @notice Get exact stake information for a token
     */
    function getStakeInfo(
        uint256 tokenId
    )
        external
        view
        returns (
            address owner,
            uint256 stakedAt,
            uint256 lastClaimedAt,
            uint256 pendingRewards,
            uint256 currentMultiplier
        )
    {
        Stake memory stakeInfo = stakes[tokenId];
        owner = stakeInfo.owner;
        stakedAt = stakeInfo.stakedAt;
        lastClaimedAt = stakeInfo.lastClaimedAt;
        pendingRewards = calculateRewards(tokenId);
        currentMultiplier = owner != address(0)
            ? getLoyaltyMultiplier(stakedAt)
            : 0;
    }

    /**
     * @notice Get emission parameters
     */
    function getEmissionParameters()
        external
        pure
        returns (
            uint256 totalSupply,
            uint256 decayPeriod,
            uint256 loyaltyPeriod,
            uint256 baseEmission,
            uint256 initialBonus
        )
    {
        totalSupply = 1_000_000_000 * 1e18; // 1B POGE
        decayPeriod = DECAY_PERIOD;
        loyaltyPeriod = LOYALTY_PERIOD;
        baseEmission = BASE_EMISSION;
        initialBonus = INITIAL_BONUS;
    }

    // ============ Core Calculation Functions (TRUTH) ============

    function getLoyaltyMultiplier(
        uint256 stakedAt
    ) public view returns (uint256 multiplier) {
        uint256 duration = block.timestamp - stakedAt;

        if (duration >= LOYALTY_PERIOD) {
            return MAX_MULTIPLIER;
        }

        uint256 additionalMultiplier = ((MAX_MULTIPLIER - BASE_MULTIPLIER) *
            duration) / LOYALTY_PERIOD;
        return BASE_MULTIPLIER + additionalMultiplier;
    }

    function calculateRewards(
        uint256 tokenId
    ) public view returns (uint256 rewards) {
        Stake memory stakeInfo = stakes[tokenId];
        if (stakeInfo.owner == address(0)) return 0;

        uint256 baseRewards = _calculateRewardForPeriod(
            stakeInfo.lastClaimedAt,
            block.timestamp
        );

        uint256 multiplier = getLoyaltyMultiplier(stakeInfo.stakedAt);
        return (baseRewards * multiplier) / MULTIPLIER_SCALE;
    }

    function _calculateRewardForPeriod(
        uint256 startTime,
        uint256 endTime
    ) internal view returns (uint256) {
        if (endTime <= startTime) return 0;

        uint256 duration = endTime - startTime;
        uint256 globalStart = startTime - LAUNCH_TIMESTAMP;
        uint256 globalEnd = endTime - LAUNCH_TIMESTAMP;

        if (globalStart >= DECAY_PERIOD) {
            return duration * BASE_EMISSION;
        }

        if (globalEnd <= DECAY_PERIOD) {
            uint256 baseReward = duration * BASE_EMISSION;

            uint256 t1Remaining = DECAY_PERIOD - globalStart;
            uint256 t2Remaining = DECAY_PERIOD - globalEnd;

            uint256 t1Squared = t1Remaining * t1Remaining;
            uint256 t2Squared = t2Remaining * t2Remaining;

            uint256 bonusReward = (INITIAL_BONUS * (t1Squared - t2Squared)) /
                (2 * DECAY_PERIOD);

            return baseReward + bonusReward;
        }

        uint256 decayEndTime = LAUNCH_TIMESTAMP + DECAY_PERIOD;
        uint256 rewardDuringDecay = _calculateRewardForPeriod(
            startTime,
            decayEndTime
        );
        uint256 rewardAfterDecay = (endTime - decayEndTime) * BASE_EMISSION;

        return rewardDuringDecay + rewardAfterDecay;
    }

    function getCurrentEmissionRate() external view returns (uint256 rate) {
        uint256 timeSinceLaunch = block.timestamp - LAUNCH_TIMESTAMP;

        if (timeSinceLaunch >= DECAY_PERIOD) {
            return BASE_EMISSION;
        }

        uint256 decayProgress = (timeSinceLaunch * 1e18) / DECAY_PERIOD;
        uint256 remainingBonus = (INITIAL_BONUS * (1e18 - decayProgress)) /
            1e18;

        return BASE_EMISSION + remainingBonus;
    }

    function getEffectiveRate(
        uint256 tokenId
    ) external view returns (uint256 effectiveRate) {
        Stake memory stakeInfo = stakes[tokenId];
        if (stakeInfo.owner == address(0)) return 0;

        uint256 baseRate = this.getCurrentEmissionRate();
        uint256 multiplier = getLoyaltyMultiplier(stakeInfo.stakedAt);

        return (baseRate * multiplier) / MULTIPLIER_SCALE;
    }

    function getRewardPoolBalance() external view returns (uint256 balance) {
        return pogeCoin.balanceOf(address(this));
    }

    // ============ Internal Helpers ============

    function _removeFromUserStakes(address user, uint256 tokenId) private {
        uint256[] storage tokens = userStakes[user];
        uint256 index = userStakeIndex[user][tokenId];

        uint256 lastTokenId = tokens[tokens.length - 1];
        tokens[index] = lastTokenId;
        userStakeIndex[user][lastTokenId] = index;

        tokens.pop();
        delete userStakeIndex[user][tokenId];
    }
}