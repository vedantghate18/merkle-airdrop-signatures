// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract ClaimAirdrop is Script {
    error ClaimAirdrop__InvalidSignatureLength();

    uint256 constant CLAIMING_AMOUNT = 25 * 1e18;
    // REPLACE WITH YOUR CLAIMING ADDRESS
    address constant CLAIMING_ADDRESS = address(0);

    bytes32 private constant PROOF_ONE =
        /** Your Proof One */;
    bytes32 private constant PROOF_TWO =
        /** Your Proof Two */;

    // PUT YOUR GENERATED SIGNATURE HERE (Like hex"6c57...")
    bytes private SIGNATURE =
        hex"Your Signature";

    function run() public {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "MerkleAirdrop",
            block.chainid
        );
        claimAirdrop(mostRecentlyDeployed);
    }

    function claimAirdrop(address airdrop) public {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = PROOF_ONE;
        proof[1] = PROOF_TWO;

        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        MerkleAirdrop(airdrop).claim(
            CLAIMING_ADDRESS,
            CLAIMING_AMOUNT,
            proof,
            v,
            r,
            s
        );
        vm.stopBroadcast();
    }

    function splitSignature(
        bytes memory signature
    ) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (signature.length != 65) {
            revert ClaimAirdrop__InvalidSignatureLength();
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        return (v, r, s);
    }
}
