
// import { ethers } from "https://cdnjs.cloudflare.com/ajax/libs/ethers/6.7.0/ethers.min.js";

// const provider = new ethers.providers.JsonRpcProvider("http://localhost:8545");
// let signer;
// let carInsuranceContract;

// const contractAddress = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9";
// const contractABI = require('.artifacts/contracts.CarInsurance.sol.CarInsurance.json');

// // On page load, connect to the contract
// async function init() {
//     if (typeof window.ethereum !== 'undefined') {
//         await ethereum.request({ method: 'eth_requestAccounts' });
//         const web3Provider = new ethers.providers.Web3Provider(window.ethereum);
//         signer = web3Provider.getSigner();
//         carInsuranceContract = new ethers.Contract(contractAddress, contractABI, signer);
//         document.getElementById("contractAddress").innerText = `Contract Address: ${contractAddress}`;
//         loadPolicies();
//     } else {
//         alert("Please install MetaMask!");
//     }
// }

// // Load available policies (example)
// async function loadPolicies() {
//     const policyCount = await carInsuranceContract.policyCount();
//     let policiesHTML = '';
//     for (let i = 0; i < policyCount; i++) {
//         const policy = await carInsuranceContract.policies(i);
//         policiesHTML += `<p>Policy ${i}: Premium ${ethers.utils.formatEther(policy.premiumAmount)} ETH</p>`;
//     }
//     document.getElementById("policyList").innerHTML = policiesHTML;
// }

// // Register user for a selected policy
// document.getElementById("registerPolicyBtn").addEventListener('click', async () => {
//     try {
//         const tx = await carInsuranceContract.registerUser(0, 0);  // Example: policyId 0, NCD 0
//         await tx.wait();
//         document.getElementById("message").innerText = "Successfully registered!";
//     } catch (error) {
//         document.getElementById("message").innerText = "Error: " + error.message;
//     }
// });

// // Initialize on page load
// window.addEventListener('load', init);
