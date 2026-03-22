// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {RayToken} from "../src/RayToken.sol";
import {ZkSyncChainChecker} from "foundry-devops/src/ZkSyncChainChecker.sol";
import {DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";

contract MerkleAirdropTest is ZkSyncChainChecker, Test {
    MerkleAirdrop public airdrop;
    RayToken public token;
    // TEST MERKLE ROOT
    bytes32 public ROOT = 0x7cdb6c21ef22a6cb5726d348e677f3e10032127425d425c5028965a30a71556e;
    uint256 public AMOUNT_TO_CLAIM = 25 * 1e18;
    uint256 public AMOUNT_TO_SEND = 4 * AMOUNT_TO_CLAIM;

    // TEST PROOFS
    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [proofOne, proofTwo];
    address gasPayer;
    address USER;
    uint256 userPrivKey;

    function setUp() public {
        if (!isZkSyncChain()) {
            // deploy with the script
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (airdrop, token) = deployer.deployMerkleAirdrop();
        }

        token = new RayToken();
        airdrop = new MerkleAirdrop(ROOT, token);
        (USER, userPrivKey) = makeAddrAndKey("USER");
        gasPayer = makeAddr("gasPayer");
    }

    function testUsersCanClaim() public {
        uint256 startingBalance = token.balanceOf(USER);
        token.mint(token.owner(), AMOUNT_TO_SEND);
        token.transfer(address(airdrop), AMOUNT_TO_SEND);
        bytes32 digest = airdrop.getMessage(USER, AMOUNT_TO_CLAIM);

        // sign a message
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivKey, digest);

        vm.prank(gasPayer);
        airdrop.claim(USER, AMOUNT_TO_CLAIM, PROOF, v, r, s);

        uint256 endingBalance = token.balanceOf(USER);
        console.log("Starting balance: %s", startingBalance);
        console.log("Ending balance: %s", endingBalance);
        assertEq(endingBalance - startingBalance, AMOUNT_TO_CLAIM);
    }

    function testRevertsIfInvalidSignature() public {
        token.mint(token.owner(), AMOUNT_TO_SEND);
        token.transfer(address(airdrop), AMOUNT_TO_SEND);
        bytes32 digest = airdrop.getMessage(USER, AMOUNT_TO_CLAIM);

        // Sign with a WRONG private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(12345, digest);

        vm.prank(gasPayer);
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidSignature.selector);
        airdrop.claim(USER, AMOUNT_TO_CLAIM, PROOF, v, r, s);
    }

    function testRevertsIfAlreadyClaimed() public {
        token.mint(token.owner(), AMOUNT_TO_SEND);
        token.transfer(address(airdrop), AMOUNT_TO_SEND);
        bytes32 digest = airdrop.getMessage(USER, AMOUNT_TO_CLAIM);

        // Sign correct message
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivKey, digest);

        vm.prank(gasPayer);
        airdrop.claim(USER, AMOUNT_TO_CLAIM, PROOF, v, r, s);

        vm.prank(gasPayer);
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__AlreadyClaimed.selector);
        airdrop.claim(USER, AMOUNT_TO_CLAIM, PROOF, v, r, s);
    }
}
