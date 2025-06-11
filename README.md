Collecting workspace informationHere's a README.md for your TimeVaultProofs contract:

# TimeVaultProofs Smart Contract

A Clarity smart contract that implements a time-locked vault system with guardian-based inheritance and document archival capabilities.

## Features

### Time-Locked Vaults
- Create inheritance vaults with designated beneficiaries and guardians
- Guardian-based approval system requiring majority consensus
- Time-lock mechanism with ~70 day inactivity threshold
- Secure asset claiming process for beneficiaries

### Document Archival
- Submit document hashes with customizable unlock schedules
- Optional metadata storage for archived documents
- Time-based release mechanism
- Verification of document ownership and status

## Functions

### Vault Management

```clarity
(create-vault (beneficiary principal) (guardians (list 5 principal)))
```
Creates a new vault with specified beneficiary and up to 5 guardians.

```clarity
(guardian-approve (owner principal))
```
Allows approved guardians to vote for unlocking a vault.

```clarity
(unlock-vault (owner principal))
```
Unlocks a vault when majority guardian approval and time threshold are met.

```clarity
(claim-assets (owner principal))
```
Allows beneficiary to claim assets from an unlocked vault.

### Document Archival

```clarity
(submit-archive (doc-hash (buff 32)) (unlock-delay uint) (meta (optional (buff 100))))
```
Archives a document hash with specified unlock delay and optional metadata.

```clarity
(release-archive (doc-hash (buff 32)))
```
Releases archived document after unlock delay period.

### Read-Only Functions

```clarity
(get-vault (owner principal))
```
Returns vault details for specified owner.

```clarity
(get-archive (doc-hash (buff 32)))
```
Returns archive details for specified document hash.

## Error Codes

- `u100`: Invalid vault operation
- `u101`: Vault already unlocked
- `u102`: Unauthorized guardian
- `u103`: Guardian already approved
- `u104`: Too many approvals
- `u105`: Unlock time not reached
- `u106`: Insufficient guardian approvals
- `u107`: Unauthorized beneficiary
- `u108`: Vault not unlocked
- `u200`: Document hash already exists
- `u201`: Unauthorized document owner
- `u202`: Document already released
- `u203`: Release time not reached
- `u204`: Document hash not found

