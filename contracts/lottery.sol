// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract lottery{
    address payable public owner;
    mapping (address => uint256) values;
    address payable[] public listOfPlayers;


    constructor(){
        owner = payable(msg.sender);
    }

    function enter() public payable{
        // $50 minimum entrance fee

        listOfPlayers.push(msg.sender);
    }

    function getEntranceFee() public {}

    function startLottery() public {}

    function endLottery() public {}

}