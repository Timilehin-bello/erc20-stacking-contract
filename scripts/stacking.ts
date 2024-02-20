import { ethers, run } from "hardhat";
import ContractABI from "../artifacts/contracts/Token.sol/Token.json";

async function main(): Promise<void> {
  // Deploy the staking contract
  const StakingContractFactory = await ethers.getContractFactory(
    "StakingERC20"
  );
  const stakingContract = await StakingContractFactory.deploy(
    "0xaaf3b2776c67b3f5691825956910c3a917bbd7d6"
  ); // ERC20 token address as a constructor argument

  console.log(`Staking contract deployed to: ${stakingContract.target}`);

  // Assume the deployer is also the staker for simplicity
  const [deployer] = await ethers.getSigners();

  // Approve the staking contract to spend deployer's tokens
  // Assuming you have the ERC20 contract ABI and the token holder has enough tokens
  const ERC20Contract = await ethers.getContractAt(
    ContractABI.abi,
    "0xaaf3b2776c67b3f5691825956910c3a917bbd7d6",
    deployer
  );
  const approveTx = await ERC20Contract.approve(
    stakingContract.target,
    ethers.parseEther("100")
  );
  await approveTx.wait();
  console.log("ERC20 tokens approved for staking.");

  // Stake tokens
  const stakeTx = await stakingContract.stake(ethers.parseEther("100"));
  await stakeTx.wait();
  console.log("Tokens staked successfully.");

  // Query staked balance
  const stakedBalance = await stakingContract.getStake(deployer.address);
  console.log(
    `Staked Amount: ${ethers.formatEther(
      stakedBalance[0]
    )} tokens at time ${new Date(
      Number(stakedBalance[1]) * 1000
    ).toLocaleString()}`
  );

  // Unstake tokens after a delay (for demonstration)
  console.log("Waiting for a period before unstaking...");
  await new Promise((resolve) => setTimeout(resolve, 15000)); // 10 seconds delay

  const unstakeTx = await stakingContract.unstake();
  await unstakeTx.wait();
  console.log("Tokens unstaked successfully.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
