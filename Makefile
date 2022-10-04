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

# Deploy
local_deploy_dkgfactory           :; forge script script/DKGFactory.s.sol:DKGFactoryDeploy --fork-url http://localhost:8545 --broadcast --verify -vvvv
arbitrum_rinkeby_deploy_dkgfactory:; forge script script/DKGFactory.s.sol:DKGFactoryDeploy --rpc-url $ARBITRUM_RINKEBY_RPC_URL --broadcast --verify -vvvv
goerli_deploy_dkgfactory          :; forge script script/DKGFactory.s.sol:DKGFactoryDeploy --rpc-url $GOERLI_RPC_URL --broadcast --verify -vvvv

local_deploy_oraclefactory           :; forge script script/OracleFactory.s.sol:OracleFactoryDeploy --fork-url http://localhost:8545 --broadcast --verify -vvvv
arbitrum_rinkeby_deploy_oraclefactory:; forge script script/OracleFactory.s.sol:OracleFactoryDeploy --rpc-url $ARBITRUM_RINKEBY_RPC_URL --broadcast --verify -vvvv
goerli_deploy_dkgfactory             :; forge script script/OracleFactory.s.sol:OracleFactoryDeploy --rpc-url $GOERLI_RPC_URL --broadcast --verify -vvvv
