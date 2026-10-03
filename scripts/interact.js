import { network } from "hardhat";
import { keccak256, toHex } from "viem";
import assert from "node:assert/strict";

async function main() {
    //connect to local node
    const { viem } = await network.create();

    //extract accounts - admin, alice, bob
    const [admin, alice, bob] = await viem.getWalletClients();
    console.log("Admin address: ", admin.account.address);
    console.log("Alice address:", alice.account.address);
    console.log("Bob address:  ", bob.account.address);

    //connecting to deployed contracts
    const identityRegistry = await viem.getContractAt(
        "IdentityRegistry",
        "0x5fbdb2315678afecb367f032d93f642f64180aa3"
    );
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

    //1. Registering and approving Alice & Bob

    //registering alice
    console.log("\n0. Registering Alice...");
    const aliceIdentityHash = keccak256(toHex("alice-data"));
    await identityRegistry.write.registerUser(
        [aliceIdentityHash, "ref-1"],
        { account: alice.account }
    );

    //check if she's registered
    const identity = await identityRegistry.read.identities([alice.account.address]);
    assert.equal(identity[0], true, "Alice didn't register properly.");
    assert.equal(identity[1], aliceIdentityHash, "The stored hash doesn't match Alice's hash.");
    console.log("Alice is registered. Her hash: ", identity[1]);

    //approve bob as requester
    console.log("\n1. Bob is being approved as requester...");
    await identityRegistry.write.registerRequester(
        [bob.account.address],
        { account: admin.account }
    );

    //check that registry lists him as approved
    const bobRequester = await identityRegistry.read.registeredRequesters([bob.account.address]);
    assert.equal(bobRequester, true, "Bob is not approved as requester properly.");
    console.log("Bob is approved:", bobRequester);

    //2. Granting consent & testing requests

    // alice grants consent to bob - level 0 (only credit check), valid for 2 days
    console.log("\n1. Alice creating consent for Bob...");
    const consentTx = await consentManager.write.createConsent(
        [bob.account.address, 0, 172800n, "Credit Check"],
        { account: alice.account }
    );
    console.log("Consent created. Tx hash:", consentTx);

    // check that alice got her token
    const tokenBalance = await token.read.balanceOf([alice.account.address]);
    assert.equal(tokenBalance, 1n, "Alice should have gotten 1 token.");
    console.log("Alice Token Balance:", tokenBalance.toString());

    // check that bob has the permission he was granted
    const permittedLevel = await consentManager.read.checkPermission(
        [bob.account.address, alice.account.address, 0]
    );
    assert.equal(permittedLevel, true, "Permission is incorrect.");
    console.log("Bob has permission for level 0:", permittedLevel);

    // bob requests wrong access - bob tries to access level 2 but has level 0
    console.log("\n2. Bob requesting wrong access to Alice's data...");
    const wrongRequest = await dataSharing.write.requestAccess(
        [alice.account.address, 2],
        { account: bob.account }
    );
    console.log("Access requested. Tx hash:", wrongRequest);

    //check that access log recorded what it had to + that access is denied
    const deniedRequest = await dataSharing.read.accessLog([0n]);
    assert.equal(deniedRequest[0].toLowerCase(), bob.account.address.toLowerCase(), "log didn't name Bob correctly as requester");
    assert.equal(deniedRequest[1].toLowerCase(), alice.account.address.toLowerCase(), "log didn't name Alice correctly as user");
    assert.equal(deniedRequest[2], 2, "log failed to record the requested level");
    assert.equal(deniedRequest[4], false, "request should be denied (requested more than consented to)");
    assert.equal(BigInt(deniedRequest[5]), 0n, "should be a zero ticket");
    console.log("Logged Result:", deniedRequest[4]);
    console.log("Ticket Hash: ", deniedRequest[5]);

    // bob requests correct access (level 0)
    console.log("\n3. Bob requesting correct access to Alice's data...");
    const correctRequest = await dataSharing.write.requestAccess(
        [alice.account.address, 0],
        { account: bob.account }
    );
    console.log("Access requested. Tx hash:", correctRequest);

    //check access log recorded all it had to + access granted
    const grantedRequest = await dataSharing.read.accessLog([1n]);
    assert.equal(grantedRequest[0].toLowerCase(), bob.account.address.toLowerCase(), "log didn't name Bob correctly as requester");
    assert.equal(grantedRequest[1].toLowerCase(), alice.account.address.toLowerCase(), "log didn't name Alice correctly as user");
    assert.equal(grantedRequest[2], 0, "log failed to record the requested level");
    assert.equal(grantedRequest[4], true, "request should be granted (requested level matches consented level)");
    assert.notEqual(BigInt(grantedRequest[5]), 0n, "should be a non-zero ticket");
    console.log("Logged Result:", grantedRequest[4]);
    console.log("Ticket Hash: ", grantedRequest[5]);

    //PART 3: Alice cheating workflow
    //note: because not limiting Alice's consent granting can be exploited by her (continuous consents
    //resulting in fast accumulation of tokens = cheating to maximize her balance with one user - bob)
    //we implement a rule that if Alice grants a permission for time T - that consent has to end first. 
    //otherwise the token WILL NOT BE ADDED. the same applies if Alice tries to cheat further and revokes the 
    //latest still active consent only to activate a new one - so long as that one is going on, any new consent will not 
    //result into a token. It will count as the new deadline for next consent though. Alice therefore 

    //alice tries to grant token again - 2 days haven't passed yet though,so no reward
    console.log("\n1. Alice tries to give another consent before the first one ended...");
    const earlyConsentTx = await consentManager.write.createConsent(
        [bob.account.address, 1, 172800n, "Credit Check"],
        { account: alice.account }
    );
    
    //check that Alice's balance still same
    const newAliceBalance = await token.read.balanceOf([alice.account.address]);
    assert.equal(newAliceBalance, 1n, "token shouldn't have been given");
    console.log("Alice Token Balance:", newAliceBalance.toString());

    //check the consent was still updated, just no reward
    //note: this restarts the clock for consent's validity expiration
    const newConsent = await consentManager.read.consentRecords(
        [alice.account.address, bob.account.address]
    );
    assert.equal(newConsent[2], 1, "the consent should be at level 1");
    console.log("Consent level is now:", newConsent[2]);

    // alice revokes her consent to try to cheat the system
    console.log("\n5. Alice revoking consent...");
    const revokeTx = await consentManager.write.revokeConsent(
        [bob.account.address],
        { account: alice.account }
    );
    console.log("Consent revoked. Tx hash:", revokeTx);

    //checking consent really switched off for bob
    const revokedConsent = await consentManager.read.consentRecords(
        [alice.account.address, bob.account.address]
    );
    assert.equal(revokedConsent[5], false, "consent shouldn't be given");
    const newPermission = await consentManager.read.checkPermission(
        [bob.account.address, alice.account.address, 0]
    );
    assert.equal(newPermission, false, "there should be no permission for Bob");
    console.log("Bob has permission after revocation:", newPermission);

    // alice grants a new consent right after revoking - but shouldn't give token because the 2 day timer still going for the old one
    console.log("\n6. Alice tries to cheat & grant new consent...");
    const newConsentTx = await consentManager.write.createConsent(
        [bob.account.address, 0, 172800n, "Credit Check"],
        { account: alice.account }
    );
    console.log("Consent created. Tx hash:", newConsentTx);

    // check that there is no token, but there is consent now
    const newBalance = await token.read.balanceOf([alice.account.address]);
    assert.equal(newBalance, 1n, "token shouldn't have been given");
    const bobPermission = await consentManager.read.checkPermission(
        [bob.account.address, alice.account.address, 0]
    );
    assert.equal(bobPermission, true, "Alice gave new consent, Bob should have permission");
    console.log("Alice Token Balance:", newBalance.toString());
    console.log("Bob has permission again:", bobPermission);


}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});