// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./IERC.sol";

contract StakingERC20 {
    address public owner;
    IERC20 public stakingToken;

    struct Stake {
        uint256 amount;
        uint256 stakeTime;
    }

    mapping(address => Stake) public stakes;

    event Staked(address indexed staker, uint256 amount);
    event Unstaked(
        address indexed staker,
        uint256 amount,
        uint256 reward,
        bool earlyWithdrawal
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event PenaltyPaid(address indexed staker, uint256 penaltyAmount);

    constructor(IERC20 _stakingToken) {
        owner = msg.sender;
        stakingToken = _stakingToken;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function stake(uint256 amount) public {
        require(amount > 0, "Cannot stake 0");
        require(stakes[msg.sender].amount == 0, "Already staked");

        require(
            stakingToken.transferFrom(msg.sender, address(this), amount),
            "Stake failed"
        );

        stakes[msg.sender] = Stake(amount, block.timestamp);

        emit Staked(msg.sender, amount);
    }

    function unstake() public {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No stakes found");

        uint256 stakeAmount = userStake.amount;
        uint256 reward = 0;
        bool earlyWithdrawal = false;

        if (block.timestamp >= userStake.stakeTime + 30 days) {
            // If unstaking after lock period, add 2% reward
            reward = (stakeAmount * 2) / 100;
        } else {
            // If unstaking before lock period, deduct 10% penalty
            uint256 penalty = (stakeAmount * 10) / 100;
            stakeAmount -= penalty; // Deduct penalty from the stake amount
            require(
                stakingToken.transfer(owner, penalty),
                "Penalty transfer failed"
            );
            emit PenaltyPaid(msg.sender, penalty);
            earlyWithdrawal = true;
        }

        userStake.amount = 0;

        uint256 totalAmount = stakeAmount + reward;
        require(
            stakingToken.transfer(msg.sender, totalAmount),
            "Unstake failed"
        );

        emit Unstaked(msg.sender, totalAmount, reward, earlyWithdrawal);
    }

    function getStake(
        address staker
    ) public view returns (uint256 stakeAmount, uint256 stakeTime) {
        Stake memory userStake = stakes[staker];
        return (userStake.amount, userStake.stakeTime);
    }
}
