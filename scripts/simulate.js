import { network } from "hardhat";
import { createPublicClient, keccak256, toHex } from "viem";
import { writeFileSync, appendFileSync} from "node:fs";

async function main(){
    //connecting to node
    const { viem } = await network.create();
    const publicClient = await viem.getPublicClient();
    
    //get accounts
    const accounts = await viem.getWalletClients();
    const admin = accounts[0];
    const bobs = accounts.slice(1,4); //requesting
    const alices = accounts.slice(4,19); //providing


    //connect to contracts - same as interact.js
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

    const file = "simulation.csv";
    writeFileSync(file, "transaction,alice,gas,ms\n");
    let start; //timestamp before Transaction
    let hash; //hash(Transaction)


    //helper to measure. because the assignemnt asks for exec time AND gas time, we use Receipt's gas measurement
    async function log(Tx, aliceNum, start, hash){
        const receipt = await publicClient.waitForTransactionReceipt({ hash });
        const ms = performance.now() - start;
        //we write transaction type Tx, number of alice, gas cost, time it took in ms
        appendFileSync(file, [Tx, aliceNum, receipt.gasUsed, ms.toFixed(2)].join(",") + "\n");
    }

    //1. admin approves all bobs - needed once for the scenario
    for (const bob of bobs){
        start = performance.now();
        hash =  await identityRegistry.write.registerRequester([bob.account.address],{ account: admin.account });
        await log("registerRequester", 0, start, hash);
    }

    /*Loop 1:
        - all alices deal with a random number of bobs
        - this simulates real world where tickets come arbitrarily
        - follows the same generic scenario -> covering all transaction types
    */
    for (let i = 0; i < alices.length; i++){
        const alice = alices[i];
        const numBobs = 1 + Math.floor(Math.random() * bobs.length); 

        const thisAliceBobs = bobs.slice(0, numBobs);
        

        //Tx 1: registering Alice for her session
        start = performance.now();
        hash  = await identityRegistry.write.registerUser([keccak256(toHex("user-data-" + i)), "ref-" + i],{ account: alice.account });
        await log("registerUser", i + 1, start, hash);

        //Loop 2: the scenario for this Alice repeated numBobs times
        for (const bob of thisAliceBobs){
            
            //alice gives bob consent: level 0 - valid for 2 days
            start = performance.now();
            hash = await consentManager.write.createConsent([bob.account.address, 0, 172800n, "Credit Check"],{ account: alice.account });
            await log("createConsent", i + 1, start, hash);

            //bob requests access for valid level
            start = performance.now();
            hash = await dataSharing.write.requestAccess([alice.account.address, 0],{ account: bob.account });
            await log("requestAccess (success)", i + 1, start, hash);
        
        
            //bob asks for wrong level
            start = performance.now();
            hash = await dataSharing.write.requestAccess([alice.account.address, 2],{ account: bob.account });
            await log("requestAccess (fail)", i + 1, start, hash);
      

            //alice revokes consent
            start = performance.now();
            hash = await consentManager.write.revokeConsent([bob.account.address],{ account: alice.account });
            await log("revokeConsent", i + 1, start, hash);
      
            //bob requests, but is denied
            start = performance.now();
            hash = await dataSharing.write.requestAccess([alice.account.address,0],{ account: bob.account });
            await log("requestAccess (fail)", i + 1, start, hash);
        }
    }

    console.log("Simulation is done.");


}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});