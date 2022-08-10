//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

import "EthereumDatetime.sol";

contract CryptoKids {

    using DateTime for uint;

    address owner;

    event LogKidFundingReceived(address walletAddress, uint amount, uint contractBalance);

    constructor() {
        owner = msg.sender;
    }


    struct Kid {
        address payable walletAddress;
        string firstName;
        string lastName;
        uint releaseTime;
        uint amount;
        bool canWithdraw;
    }

    Kid[] public kids;
    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can add kids");
        _;
    }

    function getRemainingTime(uint timestamp) public pure returns (uint day, uint month, uint year, uint hour) {
        day = DateTime.getDay(timestamp);
        month = DateTime.getMonth(timestamp);
        year = DateTime.getYear(timestamp);
        hour = DateTime.getHour(timestamp);
    }
    

    function addKid(address payable walletAddress, string memory firstName, string memory lastName, uint releaseTime, uint amount, bool canWithdraw) public onlyOwner{
        kids.push(Kid(walletAddress, firstName, lastName, releaseTime, amount, canWithdraw));
    }

    function balanceOf() public view returns(uint){
        return address(this).balance;
    }

    function balanceOfKid(address walletAddress) public view returns(uint){
        for(uint i = 0; i < kids.length; i++){
            if(kids[i].walletAddress == walletAddress){
                return kids[i].amount;
            }
        }
        return 999;
    }

    function deposit(address walletAddress) payable public {
        addToKidsBalance(walletAddress);
    }

    function addToKidsBalance(address walletAddress) private{
        for(uint i = 0; i < kids.length; i++){
            if(kids[i].walletAddress == walletAddress){
                kids[i].amount += msg.value;
                emit LogKidFundingReceived(walletAddress, msg.value, balanceOf());
            }
        }
    }

    function getIndex(address walletAddress) view private returns(uint){
        for(uint i = 0; i < kids.length; i++){
            if(kids[i].walletAddress == walletAddress){
                return i;
            }
        }

        return 999;
    }

    function availableToWithdraw(address walletAddress) public returns(bool) {
        uint i = getIndex(walletAddress);
        require(block.timestamp > kids[i].releaseTime, "You can't withdraw");
        if(block.timestamp > kids[i].releaseTime){
            kids[i].canWithdraw = true;
            return true;
        }
        else{
            return false;
        }
    }

    function withdraw(address payable walletAddress) payable public {
        uint i = getIndex(walletAddress);
        require(msg.sender == kids[i].walletAddress, "You must be the kid to withdraw");
        require(kids[i].canWithdraw == true, "You aren't able to withdraw");
        kids[i].walletAddress.transfer(kids[i].amount);
    }

}
