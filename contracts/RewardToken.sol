// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardToken is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 private rewardRate;
    uint256 private withdrawFee = 0;                // set withdraw fee 0 as default
    bool private withdrawFeeStatus = false;         // set withdraw fee disabled as default

    constructor(
        string memory _name, 
        string memory _symbol, 
        uint256 _amount, 
        uint256 _rewardRate
    ) ERC20(_name, _symbol) {
        rewardRate = _rewardRate;
        _mint(msg.sender, _amount);
    }

    /* ========== Mint & Burn for Owner ========== */    
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _to, uint256 _amount) external onlyOwner {
        _burn(_to, _amount);
    }

    /* ========== Get & Set Reward Rate ========== */    
    function getRewardRate() external view returns (uint256) {
        return rewardRate;
    }

    function setRewardRate(uint256 _rewardRate) public onlyOwner {
        require(_rewardRate > 0, "Reward rate shouldn't be zero");
        rewardRate = _rewardRate;
    }

    /* ========== Get & Set , Enable / Disable Withdraw Fee ========== */    
    function getWithdrawFee() external view returns (uint256) {
        return withdrawFee;
    }

    function setWithdrawFee(uint256 _withdrawFee) public onlyOwner {
        require(_withdrawFee > 0, "Withdraw fee shouldn't be zero");
        withdrawFee = _withdrawFee;
    }

    function getWithdrawFeeStatus() external view returns (bool) {
        return withdrawFeeStatus;
    }

    function setWithdrawFeeStatus(bool _status) public onlyOwner {
        withdrawFeeStatus = _status;
    }

}
