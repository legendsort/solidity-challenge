import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, Signer, BigNumber, constants, utils } from 'ethers';

const DECIMAL = 18;

describe("Staker Contract", () => {
  let tokenDeployer: Signer;
  let owner: Signer;
  let user1: Signer;
  let user2: Signer;
  let staker: Contract;
  let rewardToken: Contract;

  beforeEach(async () => {
    [owner, tokenDeployer, user1, user2] = await ethers.getSigners();
    const Staker = await ethers.getContractFactory('Staker');
    const RewardToken = await ethers.getContractFactory('RewardToken');
    rewardToken = await RewardToken.connect(tokenDeployer).deploy(
                    'RewardToken',
                    'RT',
                    ethers.utils.parseUnits('1000000', DECIMAL),
                    ethers.utils.parseUnits('100', DECIMAL)
                  );
    staker = await Staker.deploy(rewardToken.address, await owner.getAddress());
  });

  describe('Deployment', () => {
    it('Check deployment', async () => {
      expect(await staker.rewardToken()).to.equal(rewardToken.address);
      expect(await staker.owner()).to.equal(await owner.getAddress());
    });
  });

  describe('Reward token functions', () => {
    it('Should token owner be able to mint', async () => {
      const mintAmount = ethers.utils.parseUnits('10000', DECIMAL);
      rewardToken.mint(await user1.getAddress(), mintAmount);

      const user1Balance = await rewardToken.balanceOf(await user1.getAddress());
      expect(user1Balance).to.equal(mintAmount);
    });

    it('Should token owner be able to change reward rate', async () => {
      const rewardRate = ethers.utils.parseUnits('100', DECIMAL);
      rewardToken.connect(tokenDeployer).setRewardRate(rewardRate);

      expect(await rewardToken.getRewardRate()).to.equal(rewardRate);
    });
  });

  describe('Staker functions', () => {
    it('Should be able to deposit', async () => {
      rewardToken.mint(await user1.getAddress(), ethers.utils.parseUnits('10000', DECIMAL));

      const transferAmount = ethers.utils.parseUnits('1000', DECIMAL);
      await rewardToken.connect(user1).approve(staker.address, transferAmount);
      await staker.connect(user1).deposit(transferAmount);

      const user1Balance = await rewardToken.balanceOf(await user1.getAddress());
      expect(user1Balance).to.equal(ethers.utils.parseUnits('9000', DECIMAL));
    });

    it('Should be able to withdraw & claim rewards along with time pass', async () => {
      const mintAmount = ethers.utils.parseUnits('10000', DECIMAL);
      rewardToken.mint(await user1.getAddress(), mintAmount);
      rewardToken.mint(await user2.getAddress(), mintAmount);

      const transferAmount = ethers.utils.parseUnits('1000', DECIMAL);
      await rewardToken.connect(user1).approve(staker.address, transferAmount);
      await staker.connect(user1).deposit(transferAmount);
      const blockNumber1 = await ethers.provider.getBlockNumber();

      await ethers.provider.send("evm_mine", []); 
      await rewardToken.connect(user2).approve(staker.address, transferAmount);
      await staker.connect(user2).deposit(transferAmount);
      const blockNumber2 = await ethers.provider.getBlockNumber();

      const rewardRate: BigNumber = await rewardToken.getRewardRate();
      const reward = await staker.connect(await user1.getAddress()).checkTotalRewards();
      expect(rewardRate.mul(blockNumber2 - blockNumber1).div(2)).to.equal(reward);    // check reward amount

      await staker.connect(user1).withdraw();
    });
  });
});
