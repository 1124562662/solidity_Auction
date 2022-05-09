// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Auction.sol";

contract EnglishAuction is Auction {

    uint public initialPrice;
    uint public biddingPeriod;
    uint public minimumPriceIncrement;

    uint internal startTime;
//    bool internal finished;
    uint internal currentHighest;

    bool internal firstBid;

    address internal currentHighestBidder;


    // constructor
    constructor(address _sellerAddress,
                          address _judgeAddress,
                          address _timerAddress,
                          uint _initialPrice,
                          uint _biddingPeriod,
                          uint _minimumPriceIncrement)
             Auction (_sellerAddress, _judgeAddress, _timerAddress) {

        initialPrice = _initialPrice;
        biddingPeriod = _biddingPeriod;
        minimumPriceIncrement = _minimumPriceIncrement;

        startTime = super.time();
//        finished = false;
        currentHighest = 0;
        firstBid = true;
        currentHighestBidder = address(0);
    }

    function bid() public payable{
//        require(!finished);
        uint currentTime = super.time();
        require(currentTime < startTime + biddingPeriod);

        if (firstBid){
            require(msg.value >= initialPrice);
            firstBid = false;
        }else{
            require(msg.value >= currentHighest + minimumPriceIncrement);
        }
        balances[currentHighestBidder] += currentHighest;
        currentHighest = msg.value;
        currentHighestBidder = msg.sender;
        startTime = super.time();
    }

    // Need to override the default implementation
    function getWinner() public override view returns (address winner){
        uint currentTime = super.time();
        if (currentTime >= startTime + biddingPeriod ){
//            finished = true;
//            winnerAddress = currentHighestBidder;
//            balances[sellerAddress] += currentHighest;
            return currentHighestBidder;
        }
        return address(0);
    }
}
