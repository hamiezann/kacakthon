const hre = require("hardhat");

async function main() {
    const CarInsurance = await hre.ethers.getContractFactory("CarInsurance");
    console.log("Deploying Smart Contract...")
    const carInsurance = await CarInsurance.deploy();
    // await carInsurance.deployed();
    console.log("Contract deployed to:", carInsurance.target);
}

main()
.then(() => process.exit(0))
.catch((error) => {
    console.error( "Error deploying smart contract", error);
    process.exit(1);
});
