// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Auction.sol";

contract DutchAuction is Auction {

    uint public initialPrice;
    uint public biddingPeriod;
    uint public offerPriceDecrement;
    uint internal startTime;
    bool internal finished;


    // constructor
    constructor(address _sellerAddress,
                          address _judgeAddress,
                          address _timerAddress,
                          uint _initialPrice,
                          uint _biddingPeriod,
                          uint _offerPriceDecrement)
             Auction (_sellerAddress, _judgeAddress, _timerAddress) {

        initialPrice = _initialPrice;
        biddingPeriod = _biddingPeriod;
        offerPriceDecrement = _offerPriceDecrement;

        startTime = super.time();
        finished = false;

    }


    function bid() public payable{
        require(!finished, 'finished');
        uint currentTime = super.time();
        require(currentTime >= startTime, 'can only bid after the start time');
        require(currentTime - startTime < biddingPeriod, 'within period');
        uint currentPrice = initialPrice - (currentTime - startTime) * offerPriceDecrement;
        require(msg.value >= currentPrice);
        winnerAddress = msg.sender;
        winningPrice = currentPrice;
        finished = true;

        balances[sellerAddress] += currentPrice;
        if(msg.value - currentPrice > 0){
            balances[winnerAddress] += msg.value - currentPrice;
        }
    }

}
