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

local_deploy_1: local_deploy_dkgfactory local_deploy_oraclefactory local_add_authorized_nodes local_deploy_dkg
sepolia_deploy_1: sepolia_deploy_dkgfactory sepolia_deploy_oraclefactory sepolia_add_all_nodes sepolia_deploy_dkg

# --- Deploy ---
#  First deploy the factories
local_deploy_dkgfactory   :; forge script script/DeployDKGFactory.s.sol:DeployDKGFactory --rpc-url local --broadcast --verify -vvvv
testnet_deploy_dkgfactory :; forge script script/DeployDKGFactory.s.sol:DeployDKGFactory --rpc-url arbitrum-goerli --broadcast -vvvv --skip-simulation --slow
sepolia_deploy_dkgfactory :; forge script script/DeployDKGFactory.s.sol:DeployDKGFactory --rpc-url arbitrum-sepolia --broadcast -vvvv --skip-simulation --slow

# Test block number function
sepolia_test_block_number:; forge script script/TestBlockNumber.s.sol:TestBlockNumber --rpc-url arbitrum-sepolia -vvvv

local_deploy_oraclefactory  :; forge script script/DeployOracleFactory.s.sol:DeployOracleFactory --rpc-url local --broadcast --verify -vvvv
testnet_deploy_oraclefactory:; forge script script/DeployOracleFactory.s.sol:DeployOracleFactory --rpc-url arbitrum-goerli --broadcast -vvvv --skip-simulation --slow
sepolia_deploy_oraclefactory:; forge script script/DeployOracleFactory.s.sol:DeployOracleFactory --rpc-url arbitrum-sepolia --broadcast -vvvv --skip-simulation --slow

# Then add authorized nodes
local_add_authorized_nodes  :; forge script script/AddAuthorizedNodes.s.sol:AddAuthorizedNodes --rpc-url local --broadcast --verify -vvvv
testnet_add_authorized_nodes:; forge script script/AddAuthorizedNodes.s.sol:AddAuthorizedNodes --rpc-url wallaby --broadcast -vvvv --skip-simulation --slow
sepolia_add_authorized_nodes:; forge script script/AddAuthorizedNodes.s.sol:AddAuthorizedNodes --rpc-url arbitrum-sepolia --broadcast -vvvv --skip-simulation --slow

# Then deploy a DKG
local_deploy_dkg  :; forge script script/DeployDKGInstance.s.sol:DeployDKGInstance --rpc-url local --broadcast --verify -vvvv
testnet_deploy_dkg:; forge script script/DeployDKGInstance.s.sol:DeployDKGInstance --rpc-url arbitrum-goerli --broadcast -vvvv --skip-simulation --slow
sepolia_deploy_dkg:; forge script script/DeployDKGInstance.s.sol:DeployDKGInstance --rpc-url arbitrum-sepolia --broadcast -vvvv --skip-simulation --slow

# Then deploy an Oracle with the key created from the DKG
local_deploy_oracle  :; forge script script/DeployBN254EncryptionOracle.s.sol:DeployBN254EncryptionOracle --rpc-url local --broadcast --verify -vvvv
testnet_deploy_oracle:; forge script script/DeployBN254EncryptionOracle.s.sol:DeployBN254EncryptionOracle --rpc-url arbitrum-goerli --broadcast -vvvv --skip-simulation --slow
sepolia_deploy_oracle:; forge script script/DeployBN254EncryptionOracle.s.sol:DeployBN254EncryptionOracle --rpc-url arbitrum-sepolia --broadcast -vvvv --skip-simulation --slow

local_deploy_client:; forge script script/DeployOnlyFiles.s.sol:DeployOnlyFiles --rpc-url local --broadcast --verify -vvvv
testnet_deploy_client:; forge script script/DeployOnlyFiles.s.sol:DeployOnlyFiles --rpc-url wallaby --broadcast -vvvv --skip-simulation --slow
sepolia_deploy_client:; forge script script/DeployOnlyFiles.s.sol:DeployOnlyFiles --rpc-url arbitrum-sepolia --broadcast -vvvv --skip-simulation --slow

# Convenience target for full Arbitrum Sepolia deployment
sepolia_deploy_all: sepolia_deploy_dkgfactory sepolia_deploy_oraclefactory sepolia_add_authorized_nodes sepolia_deploy_dkg sepolia_deploy_oracle

add_authorized_nodes:; cast send ${DKG_FACTORY_ADDRESS} \
		"addAuthorizedNode(address)(bool)" \
		${NODE_3_ADDRESS} \
		--rpc-url wallaby \
		--private-key ${PRIVATE_KEY}

sepolia_add_authorized_node1:; cast send ${DKG_FACTORY_ADDRESS} \
		"addAuthorizedNode(address)(bool)" \
		${NODE_1_ADDRESS} \
		--rpc-url arbitrum-sepolia \
		--private-key ${PRIVATE_KEY}

sepolia_add_authorized_node2:; cast send ${DKG_FACTORY_ADDRESS} \
		"addAuthorizedNode(address)(bool)" \
		${NODE_2_ADDRESS} \
		--rpc-url arbitrum-sepolia \
		--private-key ${PRIVATE_KEY}

sepolia_add_authorized_node3:; cast send ${DKG_FACTORY_ADDRESS} \
		"addAuthorizedNode(address)(bool)" \
		${NODE_3_ADDRESS} \
		--rpc-url arbitrum-sepolia \
		--private-key ${PRIVATE_KEY}

# Add all three nodes at once
sepolia_add_all_nodes: sepolia_add_authorized_node1 sepolia_add_authorized_node2 sepolia_add_authorized_node3

deploy_dkg:; cast send ${DKG_FACTORY_ADDRESS} \
	"deployNewDKG()" \
	--rpc-url wallaby \
	--private-key ${PRIVATE_KEY}

sepolia_deploy_dkg_manual:; cast send ${DKG_FACTORY_ADDRESS} \
	"deployNewDKG()" \
	--rpc-url arbitrum-sepolia \
	--private-key ${PRIVATE_KEY}

deploy_oracle:; cast send ${ORACLE_FACTORY_ADDRESS} \
		"deployReencryption_BN254_G1_HGAMAL((uint256, uint256))(address)" \
		${DIST_KEY} \
		--rpc-url wallaby \
		--private-key ${PRIVATE_KEY}

sepolia_deploy_oracle_manual:; cast send ${ORACLE_FACTORY_ADDRESS} \
		"deployReencryption_BN254_G1_HGAMAL((uint256, uint256))(address)" \
		${DIST_KEY} \
		--rpc-url arbitrum-sepolia \
		--private-key ${PRIVATE_KEY}

# --- Contract Calls ---
# Send ether to dead account to progress anvil blockchain
create_block:; cast send 0x82aD00373ffDf70fD32A3D41EEdD70766e48e992 \
				--value 1.1ether \
				--private-key ${PRIVATE_KEY}

# Get the distributed key from the completed DKG
get_key:; cast call ${DKG_ADDRESS} \
			"distributedKey()(uint256,uint256)" \
			--rpc-url local

sepolia_get_key:; cast call ${DKG_ADDRESS} \
			"distributedKey()(uint256,uint256)" \
			--rpc-url arbitrum-sepolia

get_suite:; cast call ${ORACLE_ADDRESS} \
			"suite()(uint256)" \
			--rpc-url wallaby

sepolia_get_suite:; cast call ${ORACLE_ADDRESS} \
			"suite()(uint256)" \
			--rpc-url arbitrum-sepolia

# Submit Ciphertext
submit_ciphertext:; cast send ${ORACLE_ADDRESS} \
						"submitCiphertext(((uint256, uint256), uint256, (uint256, uint256), (uint256, uint256)), bytes)(uint256)" \
						"((0,0),0,(0,0),(0,0))" 0x00000000000000000000000000000000 \
						--private-key ${PRIVATE_KEY}

sepolia_submit_ciphertext:; cast send ${ORACLE_ADDRESS} \
						"submitCiphertext(((uint256, uint256), uint256, (uint256, uint256), (uint256, uint256)), bytes)(uint256)" \
						"((0,0),0,(0,0),(0,0))" 0x00000000000000000000000000000000 \
						--rpc-url arbitrum-sepolia \
						--private-key ${PRIVATE_KEY}

# Request Reencryption
request_reencryption:; cast send ${ORACLE_ADDRESS} \
						"requestReencryption(uint256,(uint256, uint256))(uint256)" \
						1 "(0,0)" \
						--private-key ${PRIVATE_KEY}

sepolia_request_reencryption:; cast send ${ORACLE_ADDRESS} \
						"requestReencryption(uint256,(uint256, uint256))(uint256)" \
						1 "(0,0)" \
						--rpc-url arbitrum-sepolia \
						--private-key ${PRIVATE_KEY}

# Check if a node is authorized
sepolia_is_authorized_node1:; cast call ${DKG_FACTORY_ADDRESS} \
						"isAuthorizedNode(address)(bool)" \
						${NODE_1_ADDRESS} \
						--rpc-url arbitrum-sepolia

sepolia_is_authorized_node2:; cast call ${DKG_FACTORY_ADDRESS} \
						"isAuthorizedNode(address)(bool)" \
						${NODE_2_ADDRESS} \
						--rpc-url arbitrum-sepolia

sepolia_is_authorized_node3:; cast call ${DKG_FACTORY_ADDRESS} \
						"isAuthorizedNode(address)(bool)" \
						${NODE_3_ADDRESS} \
						--rpc-url arbitrum-sepolia

# Get the latest DKG instance
sepolia_get_latest_dkg:; cast call ${DKG_FACTORY_ADDRESS} \
						"getLatestDKG()(address)" \
						--rpc-url arbitrum-sepolia

# Deploy and test ArbSysTest contract
sepolia_deploy_arbsys_test:; forge script script/DeployArbSysTest.s.sol:DeployArbSysTest --rpc-url arbitrum-sepolia --broadcast -vvvv --skip-simulation --slow

sepolia_test_arbsys:; forge script script/TestArbSys.s.sol:TestArbSys --rpc-url arbitrum-sepolia -vvvv

# Deploy and test ArbSysAssemblyTest contract
sepolia_deploy_arbsys_assembly_test:; forge script script/DeployArbSysAssemblyTest.s.sol:DeployArbSysAssemblyTest --rpc-url arbitrum-sepolia --broadcast -vvvv --skip-simulation --slow

sepolia_test_arbsys_assembly:; forge script script/TestArbSysAssembly.s.sol:TestArbSysAssembly --rpc-url arbitrum-sepolia -vvvv

# --- Holesky Deployment ---
holesky_deploy_dkgfactory:; forge script script/DeployDKGFactory.s.sol:DeployDKGFactory --rpc-url ${HOLESKY_RPC_URL} --broadcast --verify --etherscan-api-key ${HOLESKY_ETHERSCAN_KEY} -vvvv --slow

holesky_deploy_oraclefactory:; forge script script/DeployOracleFactory.s.sol:DeployOracleFactory --rpc-url ${HOLESKY_RPC_URL} --broadcast --verify --etherscan-api-key ${HOLESKY_ETHERSCAN_KEY} -vvvv --slow

holesky_add_authorized_node1:; cast send ${DKG_FACTORY_ADDRESS} \
		"addAuthorizedNode(address)(bool)" \
		${NODE_1_ADDRESS} \
		--rpc-url ${HOLESKY_RPC_URL} \
		--private-key ${PRIVATE_KEY}

holesky_add_authorized_node2:; cast send ${DKG_FACTORY_ADDRESS} \
		"addAuthorizedNode(address)(bool)" \
		${NODE_2_ADDRESS} \
		--rpc-url ${HOLESKY_RPC_URL} \
		--private-key ${PRIVATE_KEY}

holesky_add_authorized_node3:; cast send ${DKG_FACTORY_ADDRESS} \
		"addAuthorizedNode(address)(bool)" \
		${NODE_3_ADDRESS} \
		--rpc-url ${HOLESKY_RPC_URL} \
		--private-key ${PRIVATE_KEY}

# Add all three nodes at once
holesky_add_all_nodes: holesky_add_authorized_node1 holesky_add_authorized_node2 holesky_add_authorized_node3

holesky_deploy_dkg:; forge script script/DeployDKGInstance.s.sol:DeployDKGInstance --rpc-url ${HOLESKY_RPC_URL} --broadcast --verify --etherscan-api-key ${HOLESKY_ETHERSCAN_KEY} -vvvv --slow

holesky_deploy_dkg_manual:; cast send ${DKG_FACTORY_ADDRESS} \
	"deployNewDKG()" \
	--rpc-url ${HOLESKY_RPC_URL} \
	--private-key ${PRIVATE_KEY}

holesky_test_block_number:; forge script script/TestBlockNumber.s.sol:TestBlockNumber --rpc-url ${HOLESKY_RPC_URL} -vvvv

# Convenience target for full Holesky deployment
holesky_deploy_all: holesky_deploy_dkgfactory holesky_deploy_oraclefactory holesky_add_all_nodes holesky_deploy_dkg

holesky_deploy_oracle_manual:; cast send ${ORACLE_FACTORY_ADDRESS} \
		"deployReencryption_BN254_G1_HGAMAL((uint256, uint256), address, uint96, uint96)(address)" \
		"(${DIST_KEY})" ${NODE_1_ADDRESS} ${SUBMISSION_FEE} ${REENCRYPTION_FEE} \
		--rpc-url ${HOLESKY_RPC_URL} \
		--private-key ${PRIVATE_KEY}

holesky_deploy_client:; forge script script/DeployOnlyFiles.s.sol:DeployOnlyFiles --rpc-url ${HOLESKY_RPC_URL} --broadcast --verify --etherscan-api-key ${HOLESKY_ETHERSCAN_KEY} -vvvv --slow
