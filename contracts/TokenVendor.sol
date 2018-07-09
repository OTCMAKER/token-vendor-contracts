pragma solidity ^0.4.23;

import 'zeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';

contract TokenVendor is Ownable{
    using SafeMath for uint256;

    ERC20 public token;

    uint256 public buyTokenRate;   // 1 ETH = 30000 RING.

    uint256 public sellTokenRate;   // sellTokenRate = buyTokenRate * 11 /10

    constructor(address _token) public {
        token = ERC20(_token);
        
        buyTokenRate = 30000;
        sellTokenRate = 33000;
    }

    /// @notice If anybody sends Ether directly to this contract, consider he is
    ///  getting tokens.
    function () public payable {
        buyToken(msg.sender);

    }

    function buyToken(address _th) public payable returns (bool) {
        require(_th != 0x0);
        require(msg.value > 0);

        uint256 _toFund = msg.value;

        uint256 tokensGenerating = _toFund.mul(buyTokenRate);

        if (tokensGenerating > token.balanceOf(this)) {
            tokensGenerating = token.balanceOf(this);
            _toFund = token.balanceOf(this).div(buyTokenRate);
        }

        require(token.transfer(_th, tokensGenerating));

        // TODO: Add statistics: totalNormalTokenTransfered = totalNormalTokenTransfered.add(tokensGenerating);

        // TODO: Add statistics: totalNormalEtherCollected = totalNormalEtherCollected.add(_toFund);

        NewBuy(_th, _toFund, tokensGenerating);
          
        uint256 toReturn = msg.value.sub(_toFund);
        if (toReturn > 0) {
            _th.transfer(toReturn);
        }

        return true;
    }

    function sellToken(address _th) public returns (bool) {

    }

    // Recommended OP: buyTokenRate will be changed once a day.
    // There is a limit of price change, that is, no more than +/- 10 percentage compared to the day before.
    // If the token in yesterday consuming to fast, then token price should go higher
    // Otherwise, token price should go lower, sell pricate should be changed accordingly
    function changeBuyTokenRate(uint256 _newBuyTokenRate) public onlyOwner {
        require(_newBuyTokenRate > 0);

        emit BuyRateChanged(buyTokenRate, _newBuyTokenRate);
        buyTokenRate = _newBuyTokenRate;
    }

    function changeSellTokenRate(uint256 _newSellTokenRate) public onlyOwner {
        require(_newSellTokenRate > 0);

        emit SellRateChanged(sellTokenRate, _newSellTokenRate);
        sellTokenRate = _newSellTokenRate;
    }

    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }

        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(this);
        token.transfer(owner, balance);

        emit ClaimedTokens(_token, owner, balance);
    }


    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event BuyRateChanged(uint256 previousBuyRate, uint256 newBuyRate);
    event SellRateChanged(uint256 previousSellRate, uint256 newSellRate);
}