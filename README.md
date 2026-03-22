# 🪂 Foundry Merkle Airdrop

![Solidity](https://img.shields.io/badge/Solidity-%23363636.svg?style=for-the-badge&logo=solidity&logoColor=white)
![Foundry](https://img.shields.io/badge/Foundry-white.svg?style=for-the-badge)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)

A highly efficient, secure, and gas-optimized Token Airdrop system built using the [Foundry](https://book.getfoundry.sh/) framework.

This project solves the problem of airdropping tokens to a large number of users efficiently. By leveraging **Merkle Trees** for verification and **EIP-712** typed data signatures for authorization, it enables scalable airdrops and opens the door for gasless transaction claiming via relayers.

---

## 🌟 Key Features

- **Merkle Tree Proofs**: Instead of storing thousands of eligible addresses on-chain (which is prohibitively expensive), the contract only stores a single 32-byte Merkle Root. Users submit proofs to claim their tokens, making the airdrop infinitely scalable.
- **EIP-712 Typed Data Signatures**: Claims require a valid cryptographic signature from the eligible recipient. This completely mitigates front-running attacks and allows third-party relayers to pay the gas fee to submit the claim on behalf of the user.
- **Custom ERC20 Token**: Included is `RayToken` (RAY), the standard token minted and distributed during the airdrop.
- **Automated Forge Scripts**: Built-in, fully automated scripts using `murky` for generating the input data, building the Merkle tree, and outputting the proofs without leaving the Foundry environment.

---

## 🏗️ Architecture & Interaction Flow

1. **Tree Generation (Off-chain)**: A list of eligible addresses and amounts is compiled. A Merkle Tree is built off-chain, and the **Merkle Root** is calculated.
2. **Deployment**: The `MerkleAirdrop` contract is deployed, storing the Merkle Root and holding the balance of the `RayToken`.
3. **Signature (Off-chain)**: The eligible user signs an EIP-712 message approving the claim of their specific amount.
4. **Execution (On-chain)**: The user (or a relayer) calls the `claim` function on the contract with:
   - The user's address and amount.
   - The Merkle Proof (an array of `bytes32` hashes).
   - The EIP-712 signature (`v`, `r`, `s`).
5. **Verification**: The contract verifies the signature recovering the signer, checks that the user hasn't already claimed, and verifies the Merkle proof against the stored root. If valid, the tokens are transferred.

---

## 📂 Project Structure

| Path                               | Description                                                                                           |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `src/MerkleAirdrop.sol`            | The core airdrop contract verifying proofs and signatures.                                            |
| `src/RayToken.sol`                 | A standard ERC20 token distributed during the airdrop.                                                |
| `script/GenerateInput.s.sol`       | Script to take a list of users and format them into an input JSON file.                               |
| `script/MakeMerkle.s.sol`          | Reads the input JSON, computes the Merkle Root, and generates an output JSON with proofs for all users. |
| `script/DeployMerkleAirdrop.s.sol` | Forge script to deploy the Token and Airdrop contracts together.                                      |
| `script/Interaction.s.sol`         | Example scripts to programmatically claim the airdrop tokens.                                         |
| `test/MerkleAirdrop.t.sol`         | Comprehensive test suite proving out the logic and security of the contracts.                         |

---

## 🚀 Getting Started

### Prerequisites

Ensure you have [Foundry](https://getfoundry.sh/) installed. If you haven't, simply run:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Installation

Clone the repository and install the necessary dependencies (like OpenZeppelin and Murky):

```bash
git clone https://github.com/vedantghate18/merkle-airdrop-signatures
cd merkle-airdrop
forge install
```

### Compilation

Compile the smart contracts to ensure everything is set up properly:

```bash
forge build
```

### Testing

Run the rigorous test suite to validate the logic, including signature checks and Merkle proof verifications:

```bash
forge test -vvv
```

---

## 🛠️ Usage Guide

### 1. Generating Merkle Proofs

Before deploying, you must generate the Merkle Root and the individual proofs for your claimers based on your input list.

```bash
# First, generate the input payload
forge script script/GenerateInput.s.sol

# Second, compute the tree and output the proofs
forge script script/MakeMerkle.s.sol
```
*Note: Successful execution will generate a `target/output.json` file containing the `root`, alongside the `proof` and `leaf` hashes for each user.*

### 2. Deployment

To deploy the contracts to a local node (like Anvil) or directly to a testnet/mainnet, run the deployment script.

```bash
# Example deployment to a local Anvil node or Testnet
forge script script/DeployMerkleAirdrop.s.sol --rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY> --broadcast
```

### 3. Claiming the Airdrop

Claiming can process via the included interaction scripts if you have the Private Key context, or typically through a frontend application where a user connects their wallet (e.g., MetaMask), signs the EIP-712 payload, and submits the `claim()` transaction with their proof fetched from a database or JSON file.

---

## 🛡️ Security Considerations

- **Signature Replay Attacks**: The EIP-712 standard natively prevents cross-chain replay attacks by embedding the `chainId` into the domain separator.
- **Double Claiming**: The contract meticulously tracks claimed status in a `s_claimed` mapping to prevent a recipient from drawing tokens more than once.
- **Front-running**: Because the claim function verifies the ECDSA signature matches the account passed into the leaf calculation, malicious actors cannot swap addresses natively if they intercept the Merkle proof.

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).
