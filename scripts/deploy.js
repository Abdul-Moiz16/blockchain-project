import { network } from "hardhat";

async function main() {
    // Create the Viem connection based on your config
    const { viem } = await network.create();

    // Get the first wallet to act as the deployer
    const [deployer] = await viem.getWalletClients();
    console.log("Deploying contracts with the account:", deployer.account.address);

    // 1. Deploy Identity Registry
    const identityRegistry = await viem.deployContract("IdentityRegistry");
    console.log("IdentityRegistry deployed to:", identityRegistry.address);

    // 2. Deploy Token
    const token = await viem.deployContract("Token");
    console.log("Token deployed to:", token.address);

    // 3. Deploy Consent Manager
    // Pass constructor arguments inside an array as the second parameter
    const consentManager = await viem.deployContract("ConsentManager", [
        identityRegistry.address,
        token.address
    ]);
    console.log("ConsentManager deployed to:", consentManager.address);

    // 4. Transfer Token Ownership to Consent Manager
    // Viem uses `.write` to execute state-changing functions
    console.log("Transferring Token ownership to ConsentManager...");
    await token.write.transferOwnership([consentManager.address]);
    console.log("Ownership transferred successfully.");

    // 5. Deploy Data Sharing
    const dataSharing = await viem.deployContract("DataSharing", [
        consentManager.address
    ]);
    console.log("DataSharing deployed to:", dataSharing.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});