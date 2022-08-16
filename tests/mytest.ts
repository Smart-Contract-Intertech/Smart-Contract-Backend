import { expect } from "chai";
import {loadFixture, deployContract, MockProvider} from 'ethereum-waffle';
import { ethers } from "hardhat";
import hre from "hardhat";


describe ("ConditionalInvesment", function () {
    async function deployFixture(){                                                                 //Use this to avoid deploying the same contract over and over again for each test
        const ConditionalInvesment = await hre.ethers.getContractFactory("ConditionalInvesment");   //This is usual contract deployment
        const cond = await ConditionalInvesment.deploy();
        return {cond};
    }
    it("Should register user", async function () {
        const { cond } = await loadFixture(deployFixture);              //loadFixture is used to restore the network to a fresh state before each state (loads the saved state)
        const [owner, otherAccount] = await ethers.getSigners();        //This is used to get other addresses in the network, other accounts can be multiple ex. [owner, otherAccount1, otherAccount2]
        cond.register(owner.address);   //!! Overloaded functions does not work for some reason ?
    })

    it("Should revert getRecipients, if none exists", async function(){
        const { cond } = await loadFixture(deployFixture);              
        const [owner, otherAccount] = await ethers.getSigners();   
        await expect(cond.getRecipients()).to.be.revertedWith("No recipient registered");
    })

    it("Should regsiter receivers to the user", async function (){
        const { cond } = await loadFixture(deployFixture);              
        const [owner, otherAccount] = await ethers.getSigners();        
        cond.registerReceiver(otherAccount.address);
    })

    it("Should show receivers", async function (){
        const { cond } = await loadFixture(deployFixture);              
        const [owner, otherAccount] = await ethers.getSigners();        
        await expect(cond.getRecipients()).to.emit(cond, "RegisteredUser"); 
    })

    it("Should make invesment", async function () {                 
        const { cond } = await loadFixture(deployFixture);              
        const [owner, otherAccount] = await ethers.getSigners();        
        
        //Call contract functions
        const blockNumBefore = await ethers.provider.getBlockNumber();
        const blockBefore = await ethers.provider.getBlock(blockNumBefore);
        const timestampBefore = blockBefore.timestamp;
        await expect( cond.makeInvesment(otherAccount.address, 1000, { value: ethers.utils.parseEther("1") })).to.emit(cond, "InvesmentInfo").withArgs(owner.address, otherAccount.address, ethers.utils.parseEther("1"), timestampBefore+1, 1000, 0); 
        //I added a +1 to the block timestamp, because it actually gets the timestamp of the block before the invesment function, which takes less than a second to process 
        //The placement of "await" keyword can change, refer to hardhat documentation   
    })
    it("Should show users invesments", async function (){

        const { cond } = await loadFixture(deployFixture);              //loadFixture is used to restore the network to a fresh state before each state (loads the saved state)
        const [owner, otherAccount] = await ethers.getSigners();        //This is used to get other addresses in the network, other accounts can be multiple ex. [owner, otherAccount1, otherAccount2]
        
        await new Promise(res => setTimeout(() => res(null), 5000));    //This is needed for ethers to poll the emitted blocks, ?? polling time could be changed also

        
        const blockNumBefore = await ethers.provider.getBlockNumber();
        const blockBefore = await ethers.provider.getBlock(blockNumBefore);
        const timestampBefore = blockBefore.timestamp;
        
        await expect( cond.myInvesments()).to.emit(cond, "InvesmentInfo").withArgs(owner.address, otherAccount.address, ethers.utils.parseEther("1"), timestampBefore, 1000, 0);
        //This emit might not work as expected if there is another block between this and the makeInvesment, because of block timestamp
    })

    it("Should revert in case of unregistered accsess", async function (){
        const { cond } = await loadFixture(deployFixture);              
        const [owner, otherAccount] = await ethers.getSigners();  
        await expect(cond.connect(otherAccount).reverseInvesment(0)).to.be.revertedWith("You are not the investor, only investors can cancel an invesment.");
    })

    it("Should reverse invesments", async function (){
        const { cond } = await loadFixture(deployFixture);              
        const [owner, otherAccount] = await ethers.getSigners();
        cond.connect(owner).reverseInvesment(0);  
    })

    it("Should divide funds to recipients", async function (){
        const { cond } = await loadFixture(deployFixture);              
        const [owner, otherAccount] = await ethers.getSigners();
        cond.connect(owner).divideToRecipients(100);  
    })

    it("Should revert if inactive invesment is reversed", async function (){
        const { cond } = await loadFixture(deployFixture);              
        const [owner, otherAccount] = await ethers.getSigners();
        await expect(cond.connect(owner).reverseInvesment(0)).to.be.revertedWith("You can not cancel an inactive invesment."); 
    })
    it("Should revert if wrong address tries to withdraw", async function (){
        const { cond } = await loadFixture(deployFixture);              
        const [owner, otherAccount, otherAccount1] = await ethers.getSigners();

        cond.makeInvesment(otherAccount.address, 10, { value: ethers.utils.parseEther("1")})
        await expect(cond.connect(otherAccount1).withdrawInvesment(1)).to.be.revertedWith("This invesment is not for this address!"); 
    })

    it("Should revert if invesment not relesed yet", async function (){
        const { cond } = await loadFixture(deployFixture);              
        const [owner, otherAccount] = await ethers.getSigners();

        await expect(cond.connect(otherAccount).withdrawInvesment(1)).to.be.revertedWith("You can not withdraw the funds yet!"); 
    })
    
    it("Should show invesments made to me", async function (){
        const { cond } = await loadFixture(deployFixture);              
        const [owner, otherAccount] = await ethers.getSigners();
        await expect (cond.connect(otherAccount).invesmentsMadeToMe()).to.emit(cond, "InvesmentInfo");
    })
    it("Should revert on revise invesment", async function (){
        const { cond } = await loadFixture(deployFixture);              
        const [owner, otherAccount, otherAccount1] = await ethers.getSigners();
        await expect(cond.connect(otherAccount1).reviseInvesment(1, ethers.utils.parseEther("1"), 10)).to.be.revertedWith("You can not revise an invesment you did not make.");
        await expect(cond.connect(owner).reviseInvesment(1, ethers.utils.parseEther("100"), 10)).to.be.revertedWith("Insufficent funds to revise invesment.");
        await expect(cond.connect(owner).reviseInvesment(0, ethers.utils.parseEther("1"), 10)).to.be.revertedWith("This is an inactive invesment.");
        await expect(cond.connect(owner).reviseInvesment(1, ethers.utils.parseEther("1"), 0)).to.be.revertedWith("You can not set an invesment to be relased in a past date.");
    })
    it("Should withdraw invesment", async function (){
        const { cond } = await loadFixture(deployFixture);              
        const [owner, otherAccount] = await ethers.getSigners();
        await new Promise(res => setTimeout(() => res(null), 10000));
        cond.connect(otherAccount).withdrawInvesment(1);
    })
})