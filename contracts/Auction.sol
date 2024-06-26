// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Timer.sol";

contract Auction {

    address internal judgeAddress;
    address internal timerAddress;
    address internal sellerAddress;
    address internal winnerAddress;
    uint winningPrice;
    bool internal afterFinaliseOrWithdraw = false;
    bool internal locked;
    mapping(address=>uint) internal balances;


    // constructor
    constructor(address _sellerAddress,
                     address _judgeAddress,
                     address _timerAddress) {

        judgeAddress = _judgeAddress;
        timerAddress = _timerAddress;
        sellerAddress = _sellerAddress;
        if (sellerAddress == address(0))
          sellerAddress = msg.sender;
        locked =false;
    }

    // This is provided for testing
    // You should use this instead of block.number directly
    // You should not modify this function.
    function time() public view returns (uint) {
        if (timerAddress != address(0))
          return Timer(timerAddress).getTime();

        return block.number;
    }

    function getWinner() public view virtual returns (address winner) {
        return winnerAddress;
    }

    function getWinningPrice() public view returns (uint price) {
        return winningPrice;
    }

    // If no judge is specified, anybody can call this.
    // If a judge is specified, then only the judge or winning bidder may call.
    function finalize() public virtual {

        require(winnerAddress != address(0), 'the auction is not over.');

        if (judgeAddress != address(0)){
            require(msg.sender == judgeAddress || msg.sender == winnerAddress,
                'If a judge is specified, then only the judge or winning bidder may call.');
        }
        require(!afterFinaliseOrWithdraw);
        balances[sellerAddress] += winningPrice;
        afterFinaliseOrWithdraw = true;
    }

    // This can ONLY be called by seller or the judge (if a judge exists).
    // Money should only be refunded to the winner.
    function refund() public {

        require(winnerAddress != address(0), 'the auction is not over.');

        if (judgeAddress != address(0)){
            require(msg.sender == judgeAddress || msg.sender == sellerAddress,
                'This can ONLY be called by seller or the judge');
        }else{
            require( msg.sender == sellerAddress, 'This can ONLY be called by seller ');
        }
        require(!afterFinaliseOrWithdraw);
        balances[winnerAddress] += winningPrice;
        afterFinaliseOrWithdraw = true;
    }

    // Withdraw funds from the contract.
    // If called, all funds available to the caller should be refunded.
    // This should be the *only* place the contract ever transfers funds out.
    // Ensure that your withdrawal functionality is not vulnerable to
    // re-entrancy or unchecked-spend vulnerabilities.
    function withdraw() public {

        require(!locked, "No re-entrancy");
        locked = true;


        if (balances[msg.sender]>0){
            uint amount = balances[msg.sender];
            balances[msg.sender] -= amount;
            payable(msg.sender).transfer(amount);
        }

        locked = false;
    }

}
