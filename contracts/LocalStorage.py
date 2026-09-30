import json
from web3 import Web3
from eth_account import Account
from eth_account.messages import encode_defunct

class UserLocalStore:
    def __init__(self, rpc_url, data_sharing_address, data_sharing_abi, user_private_key):
        # State variables from UML
        self.Name = ""
        self.Email = ""
        self.AccountNumber = ""
        self.CreditTier = ""
        self.IncomeFigure = ""
        self.AttestorSignature = b""
        
        # Web3 connection to verify on-chain state
        self.w3 = Web3(Web3.HTTPProvider(rpc_url))
        self.contract = self.w3.eth.contract(address=data_sharing_address, abi=data_sharing_abi)
        self.account = Account.from_key(user_private_key)

    #implement validateTicketandServe and generateAttributeHashes