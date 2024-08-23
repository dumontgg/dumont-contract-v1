#!/bin/bash

echo "Deleting the abi/ directory"
rm -rf abi

echo "Creating the abi/ directory"
mkdir abi

echo "Exporting ABIs to abi/ directory"
forge inspect Burner abi > abi/BURNER_ABI.json
forge inspect Game abi > abi/GAME_ABI.json
forge inspect GameFactory abi > abi/GAME_FACTORY_ABI.json
forge inspect MONT abi > abi/ERC20_ABI.json
forge inspect MontRewardManager abi > abi/MONT_REWARD_MANAGER_ABI.json
forge inspect Revealer abi > abi/REVEALER_ABI.json
forge inspect TaxBasedLocker abi > abi/TAX_BASED_LOCKER_ABI.json
forge inspect Vault abi > abi/VAULT_ABI.json
