pragma solidity 0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    string public name = "Dapp Token Farm";
    IERC20 public dappToken;
    mapping(address => bool) public allowedTokens;
    address[] allowedTokensArray;
    // token address => mapping of user address=>amounts
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address => address) public tokenPriceFeedMapping;
    address[] public stakers;

    constructor(address _dappTokenAddress) {
        dappToken = IERC20(_dappTokenAddress);
    }

    function stakeToken(uint256 _amount, address token) public {
        require(_amount > 0, "Amount cannot be 0");
        if (allowedTokens[token]) {
            updateUniqueTokensStaked(msg.sender, token);
            IERC20(token).transferFrom(msg.sender, address(this), _amount);
            stakingBalance[token][msg.sender] =
                stakingBalance[token][msg.sender] +
                _amount;

            if (uniqueTokensStaked[msg.sender] == 1) {
                stakers.push(msg.sender);
            }
        }
    }

    function setPriceFeedContract(address token, address priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[token] = priceFeed;
    }

    function updateUniqueTokensStaked(address user, address token) internal {
        if (stakingBalance[token][user] <= 0) {
            uniqueTokensStaked[user] = uniqueTokensStaked[user] + 1;
        }
    }

    function tokenIsAllowed(address token) public view returns (bool) {
        require(allowedTokens[token] == true, "not allowed");
        return true;
    }

    function addAllowedTokens(address token) public onlyOwner {
        allowedTokensArray.push(token);
        allowedTokens[token] == true;
    }

    function unstakeToken(address token) public {
        uint256 balance = stakingBalance[token][msg.sender];
        require(balance > 0, "staking balance is 0");
        IERC20(token).transfer(msg.sender, balance);
        stakingBalance[token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
    }

    function issueToken() public onlyOwner {
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            address recipient = stakers[stakersIndex];
            dappToken.transfer(recipient, getUserTotalValue(recipient));
        }
    }

    function getUserTotalValue(address user) public view returns (uint256) {
        uint256 totalValue = 0;
        if (uniqueTokensStaked[user] > 0) {
            for (
                uint256 allowedTokensIndex = 0;
                allowedTokensIndex < allowedTokensArray.length;
                allowedTokensIndex++
            ) {
                totalValue =
                    totalValue +
                    getUserStakingBalanceEthValue(
                        user,
                        allowedTokensArray[allowedTokensIndex]
                    );
            }
        }
        return totalValue;
    }

    function getUserStakingBalanceEthValue(address user, address token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokensStaked[user] <= 0) {
            return 0;
        }
        return
            (stakingBalance[token][user] * getTokenEthPrice(token)) / (10**18);
    }

    function getTokenEthPrice(address token) public view returns (uint256) {
        address priceFeedAddress = tokenPriceFeedMapping[token];
        AggregatorV3Interface priceFeed =
            AggregatorV3Interface(priceFeedAddress);
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return uint256(price);
    }
}
