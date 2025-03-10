// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {VRFV2PlusWrapperConsumerBase} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFV2PlusWrapperConsumerBase.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";



contract lottery is  VRFV2PlusWrapperConsumerBase, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );
    event Received(address, uint256);

    address payable[] public listOfPlayers;
    address payable public Winner;
    uint256 public entranceFee;
    AggregatorV3Interface internal priceFeed;

    //********************* */
    // hardcoded for Sepolia
    address internal linkAddress;

    uint32 internal numWords = 2;
    uint16 internal requestConfirmations = 3;
    uint32 internal callbackGasLimit /*= 6000000*/;//Gwei
    
    uint256[] public requestIds;
    uint256 public lastRequestId;
    struct RequestStatus {
        uint256 paid; // amount paid in link
        uint256[] randomWords;
        bool fulfilled; // whether the request has been successfully fulfilled
    }
    mapping(uint256 => RequestStatus) public s_requests;
    uint256[] public myRand;


    //********************* */

    enum LOTTERY_STATES {
        OPEN,//   0
        CLOSED,// 1
        CALCULATING_WINNER
    }
    LOTTERY_STATES public lotteryState;
    //fuji: 6000000,0x86d67c3D38D2bCeE722E601025C25a575021c6EA,0x327B83F409E1D5f13985c6d0584420FA648f1F56,0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846
    //sepo: 6000000,0x694AA1769357215DE4FAC081bf1f309aDC325306,0x195f15F2d49d693cE265b4fB0fdDbE15b1850Cc1,0x779877A7B0D9E8603169DdbD7836e478b4624789
    //Wrong Wrapper Address Can cause deployment collision.
    constructor(uint32 _callbackGasLimit, address _priceFeedAddress, address _wrapperAddress, address _link)
                ConfirmedOwner(msg.sender)
                VRFV2PlusWrapperConsumerBase(_wrapperAddress) 
        {  
            linkAddress = _link;
            entranceFee = 50 * (10**18);
            priceFeed = AggregatorV3Interface(_priceFeedAddress);
            lotteryState = LOTTERY_STATES.CLOSED;
            callbackGasLimit = _callbackGasLimit;
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
    
    function randomNumCalc() public view onlyOwner returns(uint) { // Do NOT forget {"from": ownerAccount} when ever you gonna call this func using brownie
        uint rand = uint256(keccak256(abi.encodePacked(block.number,blockhash(block.number-5), block.timestamp, /*block.difficulty, /*block.prevrandao,*/ msg.data))) % 100;
        return rand;
    }

    function endLottery() public onlyOwner returns(uint256) { //external vs public?
        lotteryState = LOTTERY_STATES.CALCULATING_WINNER;
        // ***  *** *** ***
        bool enableNativePayment = false;
        bytes memory extraArgs = VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: enableNativePayment}));
        uint256 requestId;
        uint256 reqPrice;

        (requestId, reqPrice) = requestRandomness(callbackGasLimit, requestConfirmations, numWords, extraArgs);
        s_requests[requestId] = RequestStatus({
            paid: reqPrice,
            randomWords: new uint256[](numWords),
            fulfilled: false
        });

        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(lotteryState == LOTTERY_STATES.CALCULATING_WINNER, "Not Yet!");
        require(s_requests[_requestId].paid > 0, "request not found");
        
        //s_requests[_requestId].randomWords = _randomWords;
        s_requests[_requestId].fulfilled = true;
        myRand = _randomWords; // uint256[] public myRand;

        uint WinnerIndex = _randomWords[0] % listOfPlayers.length;
        Winner = listOfPlayers[WinnerIndex];
        Winner.transfer(address(this).balance);

        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
        
        listOfPlayers = new address payable[](0);
        lotteryState = LOTTERY_STATES.CLOSED;

    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function getPlayersCount() public view returns(uint){
        return listOfPlayers.length;
    }
    
    function getLinkBalance() public view returns(uint){
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        return link.balanceOf(address(this));
    }


    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

}