// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../src/Tithe.sol";

/**
 * Deploys the Tithe ERC-20 to Arc Testnet.
 *
 * Required env vars:
 *   PRIVATE_KEY           - deployer private key (hex with 0x prefix)
 *   TITHE_RECIPIENT       - address receiving the tithe
 *   TITHE_NAME            - token name (default: "Tithe Token")
 *   TITHE_SYMBOL          - token symbol (default: "TITHE")
 *   TITHE_INITIAL_SUPPLY  - initial supply in whole tokens (default: 1_000_000)
 *   TITHE_BPS             - tithe rate in basis points (default: 1000 = 10%)
 */
contract DeployTithe is Script {
    function run() external returns (Tithe tithe) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address titheRecipient = vm.envAddress("TITHE_RECIPIENT");

        string memory tokenName = vm.envOr("TITHE_NAME", string("Tithe Token"));
        string memory tokenSymbol = vm.envOr("TITHE_SYMBOL", string("TITHE"));
        uint256 initialSupplyWhole = vm.envOr("TITHE_INITIAL_SUPPLY", uint256(1_000_000));
        uint256 titheBps = vm.envOr("TITHE_BPS", uint256(1000));

        uint256 initialSupply = initialSupplyWhole * 1e18;

        vm.startBroadcast(deployerKey);
        tithe = new Tithe(tokenName, tokenSymbol, initialSupply, titheRecipient, titheBps);
        vm.stopBroadcast();

        console.log("Tithe deployed at:", address(tithe));
        console.log("Tithe recipient:", titheRecipient);
        console.log("Tithe rate (bps):", titheBps);
        console.log("Initial supply:", initialSupplyWhole);
    }
}
