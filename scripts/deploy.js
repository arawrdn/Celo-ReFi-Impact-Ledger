const hre = require("hardhat");

async function main() {
  // Hardhat provides the deployer address via getSigners()
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts to Celo Mainnet with the account:", deployer.address);

  // --- Celo Mainnet Configuration ---
  
  // Official Celo Dollar (cUSD) ERC20 address on Celo Mainnet
  // IMPORTANT: Ensure this address is correct before deploying to mainnet.
  const CUSD_MAINNET_ADDRESS = "0x765DE816845861e765Ef149ad374426ebD95A75e";
  
  // --- 1. Deploy ImpactPool Contract ---
  
  const ImpactPool = await hre.ethers.getContractFactory("ImpactPool");
  // Pass the Mainnet cUSD address to the constructor
  const impactPool = await ImpactPool.deploy(CUSD_MAINNET_ADDRESS); 
  await impactPool.waitForDeployment();

  const impactPoolAddress = await impactPool.getAddress();
  console.log("ImpactPool deployed to Mainnet at address:", impactPoolAddress);

  // --- 2. Deploy ImpactNFT Contract ---
  
  // The NFT contract needs the address of the ImpactPool contract
  const ImpactNFT = await hre.ethers.getContractFactory("ImpactNFT");
  const impactNFT = await ImpactNFT.deploy(impactPoolAddress);
  await impactNFT.waitForDeployment();

  const impactNFTAddress = await impactNFT.getAddress();
  console.log("ImpactNFT deployed to Mainnet at address:", impactNFTAddress);
  
  // --- 3. Verification & Configuration (Post-Deployment) ---

  console.log("\nDeployment complete. Please save the following addresses for verification:");
  console.log(`ImpactPool Address: ${impactPoolAddress}`);
  console.log(`ImpactNFT Address: ${impactNFTAddress}`);
  
  // NOTE: After deployment, you MUST call a function on ImpactPool 
  // to link the two contracts together (i.e., set the ImpactNFT address).
  console.log("\nACTION REQUIRED: Set the ImpactNFT address inside the ImpactPool contract for minting to work.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
