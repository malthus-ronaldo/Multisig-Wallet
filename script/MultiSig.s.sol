// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "forge-std/Script.sol";
import "../src/MultiSig.sol";

contract DeployMultiSig is Script {
    function run() external {
        // Charge les variables d'environnement
        string memory rpcUrl = vm.envString("RPC_URL");
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        string memory ownersCsv = vm.envString("OWNERS");
        uint256 confirmationsRequired = vm.envUint("CONFIRMATIONS_REQUIRED");

        // Décompose la liste des propriétaires
        address[] memory owners = parseOwners(ownersCsv);

        // Configuration du réseau
        vm.startBroadcast(privateKey);

        // Déploiement du contrat
        MultiSig multiSig = new MultiSig(owners, confirmationsRequired);

        // Afficher l'adresse du contrat déployé
        console.log("MultiSig deployed at:", address(multiSig));

        vm.stopBroadcast();
    }

    // Fonction utilitaire pour convertir une chaîne CSV en tableau d'adresses
    function parseOwners(
        string memory ownersCsv
    ) internal pure returns (address[] memory) {
        string[] memory parts = splitString(ownersCsv, ",");
        address[] memory addresses = new address[](parts.length);
        for (uint i = 0; i < parts.length; i++) {
            addresses[i] = parseAddress(parts[i]);
        }
        return addresses;
    }

    // Fonction utilitaire pour splitter une chaîne
    function splitString(
        string memory str,
        string memory delimiter
    ) internal pure returns (string[] memory) {
        uint count = 1;
        for (uint i = 0; i < bytes(str).length; i++) {
            if (bytes(str)[i] == bytes(delimiter)[0]) {
                count++;
            }
        }

        string[] memory parts = new string[](count);
        uint j = 0;
        string memory currentPart = "";
        for (uint i = 0; i < bytes(str).length; i++) {
            if (bytes(str)[i] == bytes(delimiter)[0]) {
                parts[j++] = currentPart;
                currentPart = "";
            } else {
                currentPart = string(
                    abi.encodePacked(currentPart, bytes(str)[i])
                );
            }
        }
        parts[j] = currentPart;

        return parts;
    }

    // Fonction utilitaire pour convertir une chaîne en adresse
    function parseAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        uint160 addr = 0;
        uint160 base = 16;
        for (uint i = 2; i < strBytes.length; i++) {
            uint160 digit = uint160(uint8(strBytes[i]));
            if (digit >= 48 && digit <= 57) {
                digit -= 48;
            } else if (digit >= 97 && digit <= 102) {
                digit -= 87;
            } else if (digit >= 65 && digit <= 70) {
                digit -= 55;
            } else {
                revert("Invalid address character");
            }
            addr = addr * base + digit;
        }
        return address(addr);
    }
}
