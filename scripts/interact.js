import { network } from "hardhat";

async function main() {
    const { viem } = await network.create();

    // 1. Grab your local accounts
    const [alice, bob] = await viem.getWalletClients();
    console.log("Alice address:", alice.account.address);
    console.log("Bob address:  ", bob.account.address);

    // 2. Attach to the deployed contracts using their addresses from your deploy output
    const consentManager = await viem.getContractAt(
        "ConsentManager", 
        "0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0"
    );
    const dataSharing = await viem.getContractAt(
        "DataSharing", 
        "0xdc64a140aa3e981100a9beca4e685f962f0cf6c9"
    );
    const token = await viem.getContractAt(
        "Token", 
        "0xe7f1725e7734ce288f8367e1bb143e90bb3f0512"
    );

    // 3. Step 1: Alice grants consent to Bob (Level 2 = FULL_STATEMENT, 3600 seconds)
    console.log("\n1. Alice creating consent for Bob...");
    const consentTx = await consentManager.write.createConsent(
        [bob.account.address, 2, 3600n, "Credit Check"],
        { account: alice.account }
    );
    console.log("Consent created. Tx hash:", consentTx);

    // Check Alice's token balance (she should have received 1 token as a reward)
    const aliceBalance = await token.read.balanceOf([alice.account.address]);
    console.log("Alice Token Balance:", aliceBalance.toString());

    // 4. Step 2: Bob requests access via DataSharing
    console.log("\n2. Bob requesting access to Alice's data...");
    const requestTx = await dataSharing.write.requestAccess(
        [alice.account.address, 2],
        { account: bob.account }
    );
    console.log("Access requested. Tx hash:", requestTx);

    // Read the access log at index 0 to verify the recorded ticket
    const logEntry = await dataSharing.read.accessLog([0n]);
    console.log("\nLogged Result:", logEntry[4]); // boolean isAllowed
    console.log("Ticket Hash:  ", logEntry[5]); // bytes32 ticket
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});