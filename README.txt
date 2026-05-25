MedChain - IFB452

Author: Jacob O'Toole (n11580232)

Medchain is a decentralised application for managing healthcare records through a private permissioned blockchain. Patients own their records and control access to them. All transactions are recorded on an immutable on-chain audit log. Record file contents are stored off-chain via IPFS (Pinata pinning service) and only the CID is stored on the blockchain.

Built with Solidity smart contracts deployed to the Ethereum Sepolia testnet and a single-page HTML/JavaScript frontend that talks to the contracts via MetaMask using ethers.js v5.



STAKEHOLDERS
---------------------------------------------------------------------------
 
  Patient         Self-registers, grants/revokes access to providers, views
                  own records and audit log entries.
 
  Provider        Registered by hospital admin. Uploads and updates records
                  for patients who have explicitly granted them access.
 
  Hospital Admin  Verifies providers, audits all system activity, manages
                  audit log authorisations.
 

 
ARCHITECTURE
---------------------------------------------------------------------------

Six Solidity contracts (five operational + one factory):
 
  PatientRegistry    Patient self-registration. Stores wallet address,
                     encryption public key, and existence flag.
 
  ProviderRegistry   Hospital admin registers and revokes verified
                     providers within their organisation.
 
  AccessControl      Patient grants/revokes per-provider permissions.
                     Reads from PatientRegistry and ProviderRegistry.
                     Writes events to AuditLog.
 
  RecordManager      Providers upload/update IPFS CIDs of medical records.
                     Reads from AccessControl. Writes events to AuditLog.
                     Maintains version history via previousVersion and
                     superseded fields.
 
  AuditLog           Append-only event log. Access-controlled reads:
                     hospital admin can read everything; patients can
                     only read entries where they are the subject.
 
  Deployer           Factory contract. Deploys all five contracts in a
                     single transaction, wires them together, authorises
                     AccessControl and RecordManager on AuditLog, then
                     transfers AuditLog ownership to the hospital admin.


SETUP/DEPLOYMENT
---------------------------------------------------------------------------

1. Deploy Deployer.sol in Remix IDE (Connected to Sepolia testnet through
   MetaMask) 
2. Load index.html through node.js cp (lite-server command)
3. Click connect MetaMask and load Deployer address
4. Paste Pinata JWT and save, verify connection with Test Connection button
5. Use the role tabs to interact with the system. Switch between accounts 
   in MetaMask (and reconnect) to change roles.

USAGE FLOW (END-TO-END EXAMPLE)
---------------------------------------------------------------------------
 
  Step  Account          Tab               Action
  ----  ---------------  ----------------  ------------------------------
   1.   Hospital Admin   Hospital Admin    Register a provider wallet
   2.   Patient          Patient           Register self with public key
   3.   Patient          Patient           Grant access to provider
   4.   Provider         Provider          Upload file (auto-pins to IPFS,
                                           CID stored on chain)
   5.   Patient          Patient           Refresh records, click CID link
                                           to view the file via gateway
   6.   Provider         Provider          Update record (creates new
                                           version, marks old as superseded)
   7.   Hospital Admin   Audit Log         Load all events
   8.   Patient          Audit Log         Filter by own address
   9.   Hospital Admin   System            Refresh system status