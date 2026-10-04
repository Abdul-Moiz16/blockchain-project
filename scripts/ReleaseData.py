import glob
import json 
import os
import sys

from web3 import Web3
from LocalStorage import UserLocalStore

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
#required by LocalStorage - resolves to this computer & port Hardhat is listening on
rpc_url = "http://127.0.0.1:8545"
#getting DataSharing & ConsentManager addresses
ds_address = Web3.to_checksum_address("0xdc64a140aa3e981100a9beca4e685f962f0cf6c9")
cm_address = Web3.to_checksum_address("0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0")

#getting ticket, level, alice's address & bob's signature 
ticket= sys.argv[1]
level = int(sys.argv[2])
user_address = sys.argv[3]
signature = sys.argv[4]

#converting hex text to bytes (required by LocalStore)
signature = bytes.fromhex(signature[2:] if signature.startswith("0x") else signature)

#web3 needs ABIs of the contracts, doesn't understand Solidity
#so we make the script read a compiled contract's ABI from "artifacts" folder
def get_abi(contract):
    abi_path = os.path.join(root, "artifacts", "**", contract + ".json")
    with open(glob.glob(abi_path, recursive=True)[0]) as f:
        return json.load(f)["abi"]

#get the store of data from LocalStore's UserLocalStore
#it has Alice's data Bob is requesting
data_store = UserLocalStore(
    rpc_url,
    ds_address,
    get_abi("DataSharing"),
    cm_address,
    get_abi("ConsentManager"),
    user_address
)

#for now, printing the data to terminal considered as "releasing data to Bob"
print(json.dumps(data_store.validateTicketAndServe(ticket, level, signature)))
