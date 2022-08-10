import { expect } from "chai";
import {loadFixture, deployContract} from 'ethereum-waffle';
import { ethers } from "hardhat";
import hre from "hardhat";
async function deployFixture(){                                                                 //Use this to avoid deploying the same contract over and over again for each test
    const ConditionalInvesment = await hre.ethers.getContractFactory("ConditionalInvesment");   //This is usual contract deployment
    const cond = await ConditionalInvesment.deploy();
    return {cond};
}

describe ("ConditionalInvesment", function () {

    it("Should make invesment", async function () {                 
        const { cond } = await loadFixture(deployFixture);              //loadFixture is used to restore the network to a fresh state before each state (loads the saved state)
        const [owner, otherAccount] = await ethers.getSigners();        //This is used to get other addresses in the network, other accounts can be multiple ex. [owner, otherAccount1, otherAccount2]
        
        //Call contract functions
        cond.register(owner.address);   //!! Overloaded functions does not work for some reason ?
        cond.makeInvesment(otherAccount.address, 1000);
        await expect( cond.connect(otherAccount).withdrawInvesment(0)).to.be.revertedWith("You can not withdraw the funds yet!");    //.to.be.revertedWith means we should get the error message in the brackets
        //The placement of "await" keyword can change, refer to hardhat documentation   
    })
    it("Should show users invesments", async function (){

        const { cond } = await loadFixture(deployFixture);              //loadFixture is used to restore the network to a fresh state before each state (loads the saved state)
        const [owner, otherAccount] = await ethers.getSigners();        //This is used to get other addresses in the network, other accounts can be multiple ex. [owner, otherAccount1, otherAccount2]
        //cond.register(owner.address);                                 //load fixture does not work as expected atm 
        cond.makeInvesment(otherAccount.address,1000);
        await new Promise(res => setTimeout(() => res(null), 5000));    //This is needed for ethers to poll the emitted blocks, ?? polling time could be changed also
        await expect( cond.myInvesments()).to.emit(cond, "InvesmentInfo");//.withArgs(owner.address);
    })


})