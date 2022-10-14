# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
install:; forge install
update:; forge update

# Build & test
build  :; forge build
test   :; forge test
trace   :; forge test -vvv
clean  :; forge clean
snapshot :; forge snapshot
fmt    :; forge fmt

# --- Deploy ---
#  First deploy the factories
local_deploy_dkgfactory   :; forge script script/DeployDKGFactory.s.sol:DeployDKGFactory --rpc-url local --broadcast --verify -vvvv
testnet_deploy_dkgfactory :; forge script script/DeployDKGFactory.s.sol:DeployDKGFactory --rpc-url arbitrum-goerli --broadcast -vvvv --skip-simulation --slow

local_deploy_oraclefactory  :; forge script script/DeployOracleFactory.s.sol:DeployOracleFactory --rpc-url local --broadcast --verify -vvvv
testnet_deploy_oraclefactory:; forge script script/DeployOracleFactory.s.sol:DeployOracleFactory --rpc-url arbitrum-goerli --broadcast -vvvv --skip-simulation --slow

# Then add authorized nodes
local_add_authorized_nodes  :; forge script script/AddAuthorizedNodes.s.sol:AddAuthorizedNodes --rpc-url local --broadcast --verify -vvvv
testnet_add_authorized_nodes:; forge script script/AddAuthorizedNodes.s.sol:AddAuthorizedNodes --rpc-url arbitrum-goerli --broadcast -vvvv --skip-simulation --slow

# Then deploy a DKG
local_deploy_dkg  :; forge script script/DeployDKGInstance.s.sol:DeployDKGInstance --rpc-url local --broadcast --verify -vvvv
testnet_deploy_dkg:; forge script script/DeployDKGInstance.s.sol:DeployDKGInstance --rpc-url arbitrum-goerli --broadcast -vvvv --skip-simulation --slow

# Then deploy an Oracle with the key created from the DKG
local_deploy_oracle  :; forge script script/DeployBN254EncryptionOracle.s.sol:DeployBN254EncryptionOracle --rpc-url local --broadcast --verify -vvvv
testnet_deploy_oracle:; forge script script/DeployBN254EncryptionOracle.s.sol:DeployBN254EncryptionOracle --rpc-url arbitrum-goerli --broadcast -vvvv --skip-simulation --slow


# --- Contract Calls ---
# Send ether to dead account to progress anvil blockchain
create_block:; cast send 0x000000000000000000000000000000000000dEaD \
				--value 0.1ether \
				--private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Get the distributed key from the completed DKG
get_key:; cast call 0xa16E02E87b7454126E5E10d957A927A7F5B5d2be \
			"distributedKey()(uint256,uint256)"

# Submit Ciphertext
submit_ciphertext:; cast send 0xCafac3dD18aC6c6e92c921884f9E4176737C052c \
						"submitCiphertext(((uint256, uint256), uint256), bytes)(uint256)" \
						"((0,0),0)" 0x00000000000000000000000000000000 \
						--private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 

# Request Reencryption
request_reencryption:; cast send 0xCafac3dD18aC6c6e92c921884f9E4176737C052c \
						"requestReencryption(uint256,(uint256, uint256))(uint256)" \
						1 "(0,0)" \
						--private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 
