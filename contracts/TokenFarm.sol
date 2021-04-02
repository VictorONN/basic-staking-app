pragma solidity 0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenFarm is Ownable {
    string public name = "Dapp Token Farm";
    IERC20 public dappToken;
    mapping(address => bool) public allowedTokens;
    // token address => mapping of user address=>amounts
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address=> address) public tokenPriceFeedMapping;
    address[] public stakers;

    constructor(address _dappTokenAddress) {
        dappToken = IERC20(_dappTokenAddress);
    }


    function stakeToken(uint256 _amount, address token) public {
        require(_amount > 0, "Amount cannot be 0");
        if (allowedTokens[token]) {
            updateUniqueTokensStake(msg.sender, token);
            IERC20(token).transferFrom(msg.sender, address(this));
            stakingBalance[token][msg.sender] =
                stakingBalance[token][msg.sender] +
                _amount;

            if (uniqueTokensStaked[msg.sender] == 1) {
                staker.push(msg.sender);
            }
        }
    }

    function setPriceFeedContract(address token, address PriceFeed)public onlyOwner{
        tokenPriceFeedMapping[token]=priceFeed;
    }

    function updateUniqueTokensStake(address user, address token) internal {
        if (stakingBalance[token][user] <= 0) {
            uniqueTokensStaked[user] = uniqueTokensStaked + 1;
        }
    }

    function tokenIsAllowed(address token) public returns (bool) {
        require(allowedTokens[token] == true, "not allowed");
    }

    function addAllowedTokens(address token) public onlyOwner {
        allowedTokens[token] == true;
    }

    function unstakeToken(address token) public {
        uint256 balance = stakingBalance[token][msg.sender];
        require(balance > 0, "staking balance is 0");
        IERC20(token).transfer(msg.sender, balance);
        stakingBalance[token][msg.sender] = 0;
    }

    function issueToken() public onlyOwner {
        for (uint stakersIndex = 0;
        stakersIndex < stakers.length;
        stakersIndex++){
            address recipient = staker[stakersIndex];
            dappToken.transfer(recipient, )
        }
    }
    function getUserTotalValue(address user) public view returns(uint){
        uint totalValue = 0;
        if(uniqueTokensStaked[user] > 0){
            for(
                uint256 allowedTokensIndex = 0;
                allowedTokensIndex < allowedTokens.length;
                allowedTokensIndex++
            ){
                totalValue = totalValue + getUserStakingBalanceEthValue(
                    user,
                    allowedTokens[allowedTokensIndex]
                );
            }
        }
    }

    function getUserStakingBalanceEthValue(address user, address token) public view returns (uint256){
        if(uniqueTokensStaked[user]<=0){return 0;}
        return (stakingBalance[token][user]* getTokenEthPrice(token)) / (10**18);
    }

    function getTokenEthPrice(address token) public view returns(uint256){
        address PriceFeedAddress = tokenPriceFeedMapping[token];
    }



    function getTokenEthPrice() public {}
}
