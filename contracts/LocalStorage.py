import json
from web3 import Web3
from eth_account import Account
from eth_account.messages import encode_defunct

class UserLocalStore:
    def __init__(self, rpc_url, data_sharing_address, data_sharing_abi, user_private_key):
        # State variables from UML
        self.Name = "John"
        self.Email = "somethingJohn@whatever"
        self.AccountNumber = "12345678"
        self.CreditTier = "A"
        self.IncomeFigure = "50"
        self.AttestorSignature = b"attestorsignature"
        
        # Web3 connection to verify on-chain state
        self.w3 = Web3(Web3.HTTPProvider(rpc_url))
        self.contract = self.w3.eth.contract(address=data_sharing_address, abi=data_sharing_abi)
        self.account = Account.from_key(user_private_key)

    #implement validateTicketandServe and generateAttributeHashes

    def generateAttributeHashes(self):

        # this is the hash that gets saved in the identityregistry
        payload = json.dumps({
            "Name": self.Name,
            "Email": self.Email,
            "AccountNumber": self.AccountNumber,
            "CreditTier": self.CreditTier,
            "IncomeFigure": self.IncomeFigure
        }, sort_keys=True)
        
        # Returns a 32-byte Keccak hash representing the raw data
        return Web3.keccak(text=payload).hex()

    def validateTicketAndServe(self, ticket, requested_level):
        # Validate that the ticket is structurally sound, the consent manager makes the ticket 0 if its denied
        # because it always returns a bytes32

        if not ticket or int(ticket, 16) == 0:
            return {"error": "Invalid or denied access ticket."}


        # Also confirm this exact ticket was really logged on-chain as a GRANTED access before serving anything.
        events = self.contract.events.AccessRequested.get_logs(from_block=0, to_block="latest")
        matching = [
            e for e in events
            if e.args.ticket == ticket
            and e.args.user == self.account.address
            and e.args.result is True
        ]

        if not matching:
            return {"error": "No matching granted access found on-chain."}

        # Serve data restrictively based on the DataType level requested
        # 0 = CREDIT_TIER_ONLY, 1 = INCOME_BAND, 2 = FULL_STATEMENT
        # this default gets served because the 0 is already proved by getting here.
        served_data = {
            "CreditTier": self.CreditTier,
            "AttestorSignature": self.AttestorSignature.decode('utf-8')
        }
        
        if requested_level >= 1:
            served_data["IncomeFigure"] = self.IncomeFigure
            
        if requested_level == 2:
            served_data["Name"] = self.Name
            served_data["Email"] = self.Email
            served_data["AccountNumber"] = self.AccountNumber
            
        return {
            "status": "success",
            "served_payload": served_data
        }