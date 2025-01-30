// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract lottery is Ownable {

    address payable[] public listOfPlayers;
    uint256 public entranceFee;
    AggregatorV3Interface internal priceFeed;

    enum LOTTERY_STATES {
        OPEN,//   0
        CLOSED,// 1
        CALCULATING_WINNER
    }
    LOTTERY_STATES public lotteryState;

    constructor(address _priceFeedAddress)  Ownable(msg.sender) {  // Pass msg.sender as initial owner
        entranceFee = 50 * (10**18);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        lotteryState = LOTTERY_STATES.CLOSED;
    }

    function enter() public payable{
        require(lotteryState == LOTTERY_STATES.OPEN, "Lottery not Started Yet!");
        // $50 minimum entrance fee
        require(msg.value >= getEntranceFee(), "Not enough ETH");
        listOfPlayers.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns(uint256) { 
        // there is no need to make a state change in this function
        uint8 decimals = priceFeed.decimals();
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * (10**(18-decimals));
        uint256 entranceCost = (entranceFee * 10**18)/adjustedPrice;
        return entranceCost;
    }

    function startLottery() public onlyOwner {
        require(lotteryState == LOTTERY_STATES.CLOSED, "Lottery already started");
        lotteryState = LOTTERY_STATES.OPEN;
    }

    function endLottery() public onlyOwner {

    }

}