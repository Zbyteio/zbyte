// SPDX-License-Identifier: GPL-3.0

// --.. -... -.-- - . 
// ███████╗██████╗ ██╗   ██╗████████╗███████╗
// ╚══███╔╝██╔══██╗╚██╗ ██╔╝╚══██╔══╝██╔════╝
//   ███╔╝ ██████╔╝ ╚████╔╝    ██║   █████╗  
//  ███╔╝  ██╔══██╗  ╚██╔╝     ██║   ██╔══╝  
// ███████╗██████╔╝   ██║      ██║   ███████╗
// ╚══════╝╚═════╝    ╚═╝      ╚═╝   ╚══════╝
// --.. -... -.-- - . 

pragma solidity ^0.8.9;
import "../utils/ZbyteContext.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @title StakingRewards
/// @author Forked from:
/// https://github.com/AngleProtocol/angle-core/blob/main/contracts/staking/StakingRewardsEvents.sol
/// @notice The `StakingRewards` contracts allows to stake an ERC20 token to receive as reward another ERC20
contract ZbyteStaking is ReentrancyGuard, ZbyteContext {
    using SafeERC20 for IERC20;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Recovered(address indexed tokenAddress, address indexed to, uint256 amount);
    event RewardsDurationUpdated(uint256 rewardsDuration);

    // ============================ References to contracts ========================

    /// @notice ERC20 token given as reward
    IERC20 public immutable rewardToken;

    /// @notice ERC20 token used for staking
    IERC20 public immutable stakingToken;

    /// @notice Base of the staked token, it is going to be used in the case of sanTokens
    /// which are not in base 10**18
    uint256 public immutable stakingBase;

    // ============================ Staking parameters =============================

    /// @notice Time at which distribution ends
    uint256 public periodFinish;

    /// @notice Reward per second given to the staking contract, split among the staked tokens
    uint256 public rewardRate;

    /// @notice Duration of the reward distribution
    uint256 public rewardsDuration;

    /// @notice Last time `rewardPerTokenStored` was updated
    uint256 public lastUpdateTime;

    /// @notice Helps to compute the amount earned by someone
    /// Cumulates rewards accumulated for one token since the beginning.
    /// Stored as a uint so it is actually a float times the base of the reward token
    uint256 public rewardPerTokenStored;

    /// @notice Stores for each account the `rewardPerToken`: we do the difference
    /// between the current and the old value to compute what has been earned by an account
    mapping(address => uint256) public userRewardPerTokenPaid;

    /// @notice Stores for each account the accumulated rewards
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;

    // ============================ Constructor ====================================

    /// @notice Initializes the staking contract with a first set of parameters
    /// @param _rewardToken ERC20 token given as reward
    /// @param _stakingToken ERC20 token used for staking
    constructor(
        address _rewardToken,
        address _stakingToken
    ) {
        require(_stakingToken != address(0) && _rewardToken != address(0), "0");

        // We are not checking the compatibility of the reward token between the distributor and this contract here
        // because it is checked by the `RewardsDistributor` when activating the staking contract
        // Parameters
        rewardToken = IERC20(_rewardToken);
        stakingToken = IERC20(_stakingToken);

        stakingBase = 10**IERC20Metadata(_stakingToken).decimals();
    }

    // ============================ Modifiers ======================================

    /// @notice Checks to see if the calling address is the zero address
    /// @param account Address to check
    modifier zeroCheck(address account) {
        require(account != address(0), "0");
        _;
    }

    /// @notice Called frequently to update the staking parameters associated to an address
    /// @param account Address of the account to update
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    // ============================ View functions =================================

    /// @notice Accesses the total supply
    /// @dev Used instead of having a public variable to respect the ERC20 standard
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Accesses the number of token staked by an account
    /// @param account Account to query the balance of
    /// @dev Used instead of having a public variable to respect the ERC20 standard
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /// @notice Queries the last timestamp at which a reward was distributed
    /// @dev Returns the current timestamp if a reward is being distributed and the end of the staking
    /// period if staking is done
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /// @notice Used to actualize the `rewardPerTokenStored`
    /// @dev It adds to the reward per token: the time elapsed since the `rewardPerTokenStored` was
    /// last updated multiplied by the `rewardRate` divided by the number of tokens
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * stakingBase) / _totalSupply);
    }

    /// @notice Returns how much a given account earned rewards
    /// @param account Address for which the request is made
    /// @return How much a given account earned rewards
    /// @dev It adds to the rewards the amount of reward earned since last time that is the difference
    /// in reward per token from now and last time multiplied by the number of tokens staked by the person
    function earned(address account) public view returns (uint256) {
        return
            (_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) /
            stakingBase +
            rewards[account];
    }

    // ======================== Mutative functions forked ==========================

    /// @notice Lets someone stake a given amount of `stakingTokens`
    /// @param amount Amount of ERC20 staking token that the `_msgSender()` wants to stake
    function stake(uint256 amount) external nonReentrant updateReward(_msgSender()) {
        _stake(amount, _msgSender());
    }

    /// @notice Lets a user withdraw a given amount of collateral from the staking contract
    /// @param amount Amount of the ERC20 staking token that the `_msgSender()` wants to withdraw
    function withdraw(uint256 amount) public nonReentrant updateReward(_msgSender()) {
        require(amount > 0, "89");
        _totalSupply = _totalSupply - amount;
        _balances[_msgSender()] = _balances[_msgSender()] - amount;
        stakingToken.safeTransfer(_msgSender(), amount);
        emit Withdrawn(_msgSender(), amount);
    }

    /// @notice Triggers a payment of the reward earned to the _msgSender()
    function getReward() public nonReentrant updateReward(_msgSender()) {
        uint256 reward = rewards[_msgSender()];
        if (reward > 0) {
            rewards[_msgSender()] = 0;
            rewardToken.safeTransfer(_msgSender(), reward);
            emit RewardPaid(_msgSender(), reward);
        }
    }

    /// @notice Exits someone
    /// @dev This function lets the caller withdraw its staking and claim rewards
    // Attention here, there may be reentrancy attacks because of the following call
    // to an external contract done before other things are modified, yet since the `rewardToken`
    // is mostly going to be a trusted contract controlled by governance (namely the ANGLE token),
    // this is not an issue. If the `rewardToken` changes to an untrusted contract, this need to be updated.
    function exit() external {
        withdraw(_balances[_msgSender()]);
        getReward();
    }

    // ====================== Functions added by Angle Core Team ===================

    /// @notice Allows to stake on behalf of another address
    /// @param amount Amount to stake
    /// @param onBehalf Address to stake onBehalf of
    function stakeOnBehalf(uint256 amount, address onBehalf)
        external
        nonReentrant
        zeroCheck(onBehalf)
        updateReward(onBehalf)
    {
        _stake(amount, onBehalf);
    }

    /// @notice Internal function to stake called by `stake` and `stakeOnBehalf`
    /// @param amount Amount to stake
    /// @param onBehalf Address to stake on behalf of
    /// @dev Before calling this function, it has already been verified whether this address was a zero address or not
    function _stake(uint256 amount, address onBehalf) internal {
        require(amount > 0, "90");
        stakingToken.safeTransferFrom(_msgSender(), address(this), amount);
        _totalSupply = _totalSupply + amount;
        _balances[onBehalf] = _balances[onBehalf] + amount;
        emit Staked(onBehalf, amount);
    }

    // ====================== Restricted Functions =================================

    /// @notice Adds rewards to be distributed
    /// @param reward Amount of reward tokens to distribute
    /// @dev This reward will be distributed during `rewardsDuration` set previously
    function notifyRewardAmount(uint256 reward)
        external
        onlyOwner
        nonReentrant
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            // If no reward is currently being distributed, the new rate is just `reward / duration`
            rewardRate = reward / rewardsDuration;
        } else {
            // Otherwise, cancel the future reward and add the amount left to distribute to reward
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration;
        }

        // Ensures the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of `rewardRate` in the earned and `rewardsPerToken` functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = rewardToken.balanceOf(address(this));
        require(rewardRate <= balance / rewardsDuration, "91");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration; // Change the duration
        emit RewardAdded(reward);
    }

    /// @notice Withdraws ERC20 tokens that could accrue on this contract
    /// @param tokenAddress Address of the ERC20 token to withdraw
    /// @param to Address to transfer to
    /// @param amount Amount to transfer
    /// @dev A use case would be to claim tokens if the staked tokens accumulate rewards
    function recoverERC20(
        address tokenAddress,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(tokenAddress != address(stakingToken) && tokenAddress != address(rewardToken), "20");

        IERC20(tokenAddress).safeTransfer(to, amount);
        emit Recovered(tokenAddress, to, amount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }
}