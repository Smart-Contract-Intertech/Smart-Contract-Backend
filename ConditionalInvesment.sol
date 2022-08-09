// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

contract ConditionalInvesment{

    struct user{
        address userAddress;
        uint[] recipients;
        uint[] myInvesments;
        uint[] invesmentsToMe;
        uint userNumber;
        uint funds;
    }

    struct invesment{
        address  invester;
        address  receiver;
        uint amount;
        uint timeOfInvesment;   //In terms of seconds
        uint timeForRelease;    //Timestamp of the block
        bool isReversable;      //Unused
        bool isActive;          
        uint invesmentNo;
    }

    invesment[] invesments;     // ?? Can be improved using maps
    user[] users;

    event newRegister(uint userNo);     //Solidity can only use return in its own code
    //We need events to communicate with front-end

    //Solidity does not suppor default arguments
    //Overloaded functions caused problems in testing, so I commented them out

    /*
    function register() public returns(uint userNo) {
        //add a new user to "users" array

        for(uint i = 0; i < users.length; i++){
            require(users[i].userAddress != msg.sender, "You are already registered!");
        }

        uint[] memory recipients;                    //!! Not sure about using "memory" keyword on this block
        uint[] memory myInvesments;
        uint[] memory invesmentsToMe;
        uint userNumber = users.length + 1;
        uint funds = 0;
        user memory newUser = user(msg.sender, recipients, myInvesments, invesmentsToMe, userNumber, funds);
        users.push(newUser);
        userNo = users.length;
        emit newRegister(userNo);
        return userNo;
    }
    */ 

    function register(address userAddress) public returns(uint userNo) {
        //add a new user to "users" array

        for(uint i = 0; i < users.length; i++){
            require(users[i].userAddress != userAddress, "You are already registered!");
        }

        uint[] memory recipients;                    //!! Not sure about using "memory" keyword on this block
        uint[] memory myInvesments;
        uint[] memory invesmentsToMe;
        uint userNumber = users.length + 1;
        uint funds = 0;
        user memory newUser = user(userAddress, recipients, myInvesments, invesmentsToMe, userNumber, funds);
        users.push(newUser);
        userNo = users.length;
        emit newRegister(userNo);
        return userNo;
    }



    function registerReceiver(uint userNumber, address receiver) public returns(uint userNo) {
        //add user to "recipients" array
        //if the address is not a user in the contract, add the address using the "register" function

        require(users[userNumber].userAddress == msg.sender, "Your address does not match with user number!");

        for(uint i = 0; i < users.length; i++){         //We iterate through users to find if they 
            if(users[i].userAddress == receiver){
                users[userNumber].recipients.push(i); //add the user number of the recipient to the msg.sender's "recipients" array
                userNo = userNumber;
                return userNo;
            }
        }
        userNo = register(receiver);        //If this address is nor registered, we register it
        return userNo;

    }

    function divideToRecipients(uint userNumber, uint timeForRelease) public {
        //divide all the eth to recipients as invesments

        require(users[userNumber].userAddress == msg.sender, "Your address does not match with user number!");
        //for now it divides equally

        require(users[userNumber].funds != 0, "You have no funds to divide.");
        require(users[userNumber].recipients.length != 0, "You have no recipients to invest to.");

        //for now it divides equally
        uint invesmentAmount = users[userNumber].funds / users[userNumber].recipients.length;

        for(uint i = 0; i < users[userNumber].recipients.length; i++){  //Loop through all the registered recipients
            uint recipientIndex = users[userNumber].recipients[i];
            address recipientAddress = users[recipientIndex].userAddress;
            uint invesmentNo = invesments.length + 1;
            invesments.push(invesment(msg.sender, recipientAddress, invesmentAmount, block.timestamp, timeForRelease, true, true, invesmentNo)); //add a new invesment for every recipient
            users[userNumber].myInvesments.push(invesmentNo);        //add this invesment to the users' arrays
            users[recipientIndex].invesmentsToMe.push(invesmentNo);
        }
    }

    event InvesmentToMe(uint amount, uint timeForRelease);
    function invesmentsMadeToMe(uint userNumber) public {
        //return the sum of the invesments from "invesmentsToMe" array
        require(users[userNumber].userAddress == msg.sender, "Your address does not match with user number!");

        for(uint i = 0; i < users[userNumber].invesmentsToMe.length; i++){
            uint invesmentNo = users[userNumber].invesmentsToMe[i];
            emit InvesmentToMe(invesments[invesmentNo].amount, invesments[invesmentNo].timeForRelease);

        }

    }

    function reverseInvesment(uint userNumber, uint invesmentNo) payable public {
        //cancel an invesment
        require(invesments[invesmentNo].invester == msg.sender, "You are not the investor, only investors can cancel an invesment.");
        require(invesments[invesmentNo].isActive == true, "You can not cancel an inactive invesment.");
        require(users[userNumber].userAddress == msg.sender, "Your address does not match with user number!");

        invesments[invesmentNo].isActive = false;
        users[userNumber].funds = users[userNumber].funds + invesments[invesmentNo].amount;
    }

    function makeInvesment(address  receiver, uint timeForRelease) payable public {
        uint invesmentNo = invesments.length + 1;
        invesments.push(invesment(msg.sender, receiver, msg.value , block.timestamp, timeForRelease, true, true, invesmentNo));
    }

    function withdrawInvesment(uint invesmentNo) payable public {
        require(invesments[invesmentNo].receiver == msg.sender, "This invesment is not for this address!");
        require(invesments[invesmentNo].isActive, "You can not withdraw from an inactive invesment.");
        require((invesments[invesmentNo].timeOfInvesment + invesments[invesmentNo].timeForRelease) <  block.timestamp, "You can not withdraw the funds yet!");
        invesments[invesmentNo].isActive = false;
        payable(msg.sender).transfer(invesments[invesmentNo].amount);
    }
}