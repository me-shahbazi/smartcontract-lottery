// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract lottery{
    address payable public recipient;

    constructor(){
        recipient = payable(msg.sender);
    }
}