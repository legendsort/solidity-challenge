//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface RewardTokenInterface is IERC20 {
    function getRewardRate() external view returns (uint256);
    function getWithdrawFee() external view returns (uint256);
    function getWithdrawFeeStatus() external view returns (bool);
}

contract Staker is Ownable {
    using SafeMath for uint256;

    RewardTokenInterface public immutable rewardToken;

    struct StakerInfo {
        uint256 stakeAmount;
        uint256 rewardAmount;
        uint256 lastBlockNumber;
    }
    mapping(address => StakerInfo) public stakers;          // user info
    uint256 public totalSupply;                         // total stake amount

    constructor(
        address _rewardToken,
        address _initialOwner
    ) {
        require(_rewardToken != address(0), "Invalid reward token");
        require(_initialOwner != address(0), "Invalid initial owner");
        rewardToken = RewardTokenInterface(_rewardToken);
        transferOwnership(_initialOwner);
    }

    /* ========== USER FUNCTIONS ========== */

    function _calcReward(address _account) internal view returns (uint256) {
        return rewardToken.getRewardRate()
                .mul(block.number - stakers[_account].lastBlockNumber)
                .mul(stakers[_account].stakeAmount)
                .div(totalSupply); 
    }

    /* ========== Stake Token ========== */    
    function deposit(uint256 _amount) external {
        require(_amount > 0, "Deposit amount shouldn't be zero");

        uint256 _rewardAmount = 0;
        if (stakers[msg.sender].stakeAmount > 0) {                                              // calc reward if already staked
            _rewardAmount = _calcReward(msg.sender);
        }

        totalSupply = totalSupply.add(_amount);                                                 // update total staked amount
        stakers[msg.sender].stakeAmount = stakers[msg.sender].stakeAmount.add(_amount);         // update user staked amount
        stakers[msg.sender].rewardAmount = stakers[msg.sender].rewardAmount.add(_rewardAmount); // update user reward amount
        stakers[msg.sender].lastBlockNumber = block.number;                                     // update last block number for the user

        rewardToken.transferFrom(msg.sender, address(this), _amount);

        emit Deposited(msg.sender, _amount);
    }

    /* ========== Withdraw Stake + Reward ========== */    
    function withdraw() external {
        uint256 _stakeAmount = stakers[msg.sender].stakeAmount;
        require(_stakeAmount > 0, "User should stake first to withdraw");

        uint256 _newRewardAmount = _calcReward(msg.sender);
        uint256 _rewardAmount = stakers[msg.sender].rewardAmount.add(_newRewardAmount);

        totalSupply = totalSupply.sub(_stakeAmount);
        stakers[msg.sender].stakeAmount = 0;
        stakers[msg.sender].rewardAmount = 0;
        stakers[msg.sender].lastBlockNumber = block.number;

        uint256 _withdraw = _stakeAmount.add(_rewardAmount);
        if (rewardToken.getWithdrawFeeStatus()) {
            require(_withdraw > rewardToken.getWithdrawFee(), "Withdraw amount shouldn't be smaller than Fee");
            _withdraw = _withdraw.sub(rewardToken.getWithdrawFee());
        }
        rewardToken.transfer(msg.sender, _withdraw);

        emit Withdrawn(msg.sender, _withdraw);
    }

    /* ========== Check User Rewards ========== */    
    function checkTotalRewards() external view returns (uint256) {
        uint256 _newRewardAmount = _calcReward(msg.sender);
        uint256 _rewardAmount = stakers[msg.sender].rewardAmount.add(_newRewardAmount);
        return _rewardAmount;
    }

    /* ========== Claim Rewards Only ========== */    
    function claimRewards() external {
        uint256 _newRewardAmount = _calcReward(msg.sender);
        uint256 _rewardAmount = stakers[msg.sender].rewardAmount.add(_newRewardAmount);
        require(_rewardAmount > 0, "User don't have any reward");

        stakers[msg.sender].rewardAmount = 0;
        stakers[msg.sender].lastBlockNumber = block.number;

        rewardToken.transfer(msg.sender, _rewardAmount);

        emit RewardClaimed(msg.sender, _rewardAmount);
    }


    /* ========== EVENTS ========== */

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
}
