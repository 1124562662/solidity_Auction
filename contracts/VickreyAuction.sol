// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Auction.sol";

contract VickreyAuction is Auction {

    uint public minimumPrice;
    uint public biddingDeadline;
    uint public revealDeadline;
    uint public bidDepositAmount;

    mapping(address =>bytes32 ) internal commitments;
//    mapping(address =>uint) internal bidMapping;
    address[] internal bidAddress;
    uint[] internal bidValues;

    // constructor
    constructor(address _sellerAddress,
                            address _judgeAddress,
                            address _timerAddress,
                            uint _minimumPrice,
                            uint _biddingPeriod,
                            uint _revealPeriod,
                            uint _bidDepositAmount)
             Auction (_sellerAddress, _judgeAddress, _timerAddress) {

        minimumPrice = _minimumPrice;
        bidDepositAmount = _bidDepositAmount;
        biddingDeadline = time() + _biddingPeriod;
        revealDeadline = time() + _biddingPeriod + _revealPeriod;
    }

    // Record the player's bid commitment
    // Make sure exactly bidDepositAmount is provided (for new bids)
    // Bidders can update their previous bid for free if desired.
    // Only allow commitments before biddingDeadline
    function commitBid(bytes32 bidCommitment) public payable {
        require(time() < biddingDeadline);
        if (commitments[msg.sender] == 0){
            // first time bid
            require(msg.value == bidDepositAmount);
        }else{
            require(msg.value == 0);
        }
        commitments[msg.sender] = bidCommitment;
    }

    // Check that the bid (msg.value) matches the commitment.
    // If the bid is correctly opened, the bidder can withdraw their deposit.
    function revealBid(bytes32 nonce) public payable{
        require(time() >=biddingDeadline);
        require(time() < revealDeadline);
        uint  bidValue = msg.value;
        require( keccak256(abi.encodePacked( bidValue, nonce)) == commitments[msg.sender]);
        commitments[msg.sender] = 0;
//
//        bidMapping[msg.sender] = bidValue;
        bidAddress.push(msg.sender);
        bidValues.push(bidValue);
    }

    // Need to override the default implementation
    function getWinner() public override view returns (address winner){
        require(time()>= revealDeadline);

        if(bidValues.length == 0){
            return address(0);
        }

        if(bidValues.length == 1){
            return bidAddress[0];
        }

        if (bidValues.length > 1){
            address firstAddress = address(0);
            uint firstPrice = 0;

            for (uint i = 0; i < bidValues.length; i++){
                if(bidValues[i] >= firstPrice){
                    firstPrice = bidValues[i];
                    firstAddress = bidAddress[i];
                }
            }
            return firstAddress;
        }
        return address(0);
    }

    // finalize() must be extended here to provide a refund to the winner
    // based on the final sale price (the second highest bid, or reserve price).
    function finalize() public override {
        require(time()>= revealDeadline);

        if(bidValues.length == 1){
            winnerAddress = bidAddress[0];
            winningPrice = minimumPrice;
            balances[winnerAddress] = bidDepositAmount + bidValues[0] - winningPrice;
        }
        if (bidValues.length > 1){
            address firstAddress = address(0);
            uint firstPrice = 0;
            uint secondPrice = 0;

            for (uint i = 0; i < bidValues.length; i++){
                if(bidValues[i] >= firstPrice){
                    secondPrice = firstPrice;
                    firstPrice = bidValues[i];
                    firstAddress = bidAddress[i];
                }else{
                    if(bidValues[i] >= secondPrice){
                        secondPrice = bidValues[i];
                    }
                }
            }

            winnerAddress = firstAddress;
            winningPrice = secondPrice;

            for (uint i = 0; i < bidValues.length; i++){
                if (bidAddress[i] != winnerAddress){
                    balances[bidAddress[i]] = bidDepositAmount + bidValues[i];
                }
            }
            balances[winnerAddress] = (bidDepositAmount + firstPrice - winningPrice);

        }

        require(winnerAddress != address(0), 'the auction is not over.');
        require(!afterFinaliseOrWithdraw);
        balances[sellerAddress] += winningPrice;
        afterFinaliseOrWithdraw = true;
    }

}
