// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";


contract lottery{
    address payable public owner;
    mapping (address => uint256) values;
    address payable[] public listOfPlayers;
    uint256 public entranceFee;
    AggregatorV3Interface internal priceFeed;

    constructor(address _priceFeedAddress) {
        owner = payable(msg.sender);
        entranceFee = 50 * (10**18);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function enter() public payable{
        // $50 minimum entrance fee

        listOfPlayers.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns(uint256) { 
        // there is no need to make a state change in this function
        uint8 decimals = priceFeed.decimals();
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * (10**(18-decimals));
        return adjustedPrice;
    }

    function startLottery() public {}

    function endLottery() public {}

}