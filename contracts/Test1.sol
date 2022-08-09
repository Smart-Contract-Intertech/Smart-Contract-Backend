// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;



library StringUtils {
    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive numbe if `_b` is smaller.
    function compare(string memory _a, string memory _b) public pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }
    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string memory _a, string memory _b) public pure returns (bool) {
        return compare(_a, _b) == 0;
    }
    /// @dev Finds the index of the first occurrence of _needle in _haystack
    function indexOf(string memory _haystack, string memory _needle) public pure returns (int)
    {
    	bytes memory h = bytes(_haystack);
    	bytes memory n = bytes(_needle);
    	if(h.length < 1 || n.length < 1 || (n.length > h.length)) 
    		return -1;
    	else if(h.length > (2**128 -1)) // since we have to be able to return -1 (if the char isn't found or input error), this function must return an "int" type with a max length of (2^128 - 1)
    		return -1;									
    	else
    	{
    		uint subindex = 0;
    		for (uint i = 0; i < h.length; i ++)
    		{
    			if (h[i] == n[0]) // found the first char of b
    			{
    				subindex = 1;
    				while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) // search until the chars don't match or until we reach the end of a or b
    				{
    					subindex++;
    				}	
    				if(subindex == n.length)
    					return int(i);
    			}
    		}
    		return -1;
    	}	
    }
}

contract Test1{

    address owner;

    constructor(){
        owner = msg.sender;
    }

    struct User{
        address walletAddress;
        string name;
        uint amount;
        bool isInvestor;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    /*modifier onlyInvestor(){

        for(uint i = 0; i < users.length; i++){
            if(users[i].isInvestor == true){

            }
        }
        require(msg.sender ==  "Only owner can add kids");
        _;
    }*/

    User[] public users;
    User[] public kidsArray;
    mapping(address => User) public investors;
    mapping(address => User[]) public investorKidConnection;

    function addUser(address walletAddress, string memory name, uint amount, bool isInvestor) public onlyOwner{
        users.push(User(walletAddress, name, amount, isInvestor));
    }

    function addToInvestors(address walletAddress) public onlyOwner{
        User memory user = getUserByAddress(walletAddress);
        if(userExists(user.walletAddress)){
            investors[walletAddress] = user;
        }
        else{
            revert("User does not exist");
        }
    }

    function addKidToInvestor(address investorAddress, address kidAddress) public onlyOwner{
        User memory kid = getKidByAddress(kidAddress);
        kidsArray.push(kid);

        investorKidConnection[investorAddress] = kidsArray;
    }

    function getUserByAddress(address walletAddress) public returns(User memory user){
        for(uint i = 0; i < users.length; i++){
            if(users[i].walletAddress == walletAddress){
                users[i].isInvestor = true;
                return users[i];
            }
        }
        revert("Invalid Wallet Address");
    }

    function getKidByAddress(address walletAddress) public view returns(User memory kid){
        for(uint i = 0; i < users.length; i++){
            if(users[i].walletAddress == walletAddress){
                return users[i];
            }
        }
        revert("Invalid Wallet Address");
    }

    function getKidsOfInvestor(address walletAddress) public view returns(User[] memory){
        //User memory user = getUserByAddress(walletAddress);
        return investorKidConnection[walletAddress];
        //for(uint i = 0; i < investorKidConnection[walletAddress].length; i++)
    }

    function investorPermission(address walletAddress) public returns(bool){
        User memory user = getUserByAddress(walletAddress);
        return user.isInvestor;
    }

    function userExists(address walletAddress) public view returns(bool){
        for(uint i = 0; i < users.length; i++){
            if(users[i].walletAddress == walletAddress){
                return true;
            }
        }
        return false;
    }

    function investorExists(address walletAddress) public view returns(bool){

        if(StringUtils.equal(investors[walletAddress].name,"")){
            return false;
        }

        return true;
    }

    function transfer(address walletAddress) payable public {
        transferToAddress(walletAddress);
    }

    function transferToAddress(address walletAddress) private {
        for(uint i = 0; i < users.length; i++){
            if(users[i].walletAddress == walletAddress){
                users[i].amount += msg.value;
            }
        }
    }

    function balanceOf(address walletAddress) public view returns(uint){
        for(uint i = 0; i < users.length; i++){
            if(users[i].walletAddress == walletAddress){
                return users[i].amount;
            }
        }
        return 999;
    }




}