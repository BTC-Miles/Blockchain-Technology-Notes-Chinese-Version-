package main

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"log"
	"math/big"
	"strings"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

const (
	infuraURL          = "https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID" // 替换为你的Infura项目ID
	contractAddress    = "0xYourContractAddress"                               // 替换为部署的合约地址
	ownerPrivateKeyHex = "0xYourPrivateKey"                                    // 替换为合约所有者的私钥
	chainID            = 1                                                     // Mainnet的链ID是1，测试网络可以是3, 4, 5, 42等
	contractABI        = `YOUR_CONTRACT_ABI`                                   // 替换为你的合约ABI字符串
)

func main() {
	// 初始化以太坊客户端
	client, err := ethclient.Dial(infuraURL)
	if err != nil {
		log.Fatalf("Failed to connect to the Ethereum client: %v", err)
	}

	// 获取私钥
	privateKey, err := crypto.HexToECDSA(strings.TrimPrefix(ownerPrivateKeyHex, "0x"))
	if err != nil {
		log.Fatalf("Failed to parse private key: %v", err)
	}

	// 从私钥中导出公钥和地址
	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatalf("Failed to cast public key to ECDSA")
	}
	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)

	// 查询质押状态
	queryStakingStatus(client, fromAddress)

	// 获取奖励信息
	queryRewards(client, fromAddress)
}

// 查询质押状态
func queryStakingStatus(client *ethclient.Client, stakerAddress common.Address) {
	contractAddr := common.HexToAddress(contractAddress)
	parsedABI, err := abi.JSON(strings.NewReader(contractABI))
	if err != nil {
		log.Fatalf("Failed to parse contract ABI: %v", err)
	}

	// 调用合约的stakes方法
	stakeFnData, err := parsedABI.Pack("stakes", stakerAddress)
	if err != nil {
		log.Fatalf("Failed to pack stakes function data: %v", err)
	}

	callMsg := ethereum.CallMsg{
		To:   &contractAddr,
		Data: stakeFnData,
	}

	result, err := client.CallContract(context.Background(), callMsg, nil)
	if err != nil {
		log.Fatalf("Failed to call contract: %v", err)
	}

	var amount, timestamp *big.Int
	err = parsedABI.UnpackIntoInterface(&[]interface{}{&amount, &timestamp}, "stakes", result)
	if err != nil {
		log.Fatalf("Failed to unpack result: %v", err)
	}

	fmt.Printf("Staked Amount: %s ETH\n", amount.String())
	fmt.Printf("Stake Timestamp: %d\n", timestamp.Uint64())
}

// 获取奖励信息
func queryRewards(client *ethclient.Client, stakerAddress common.Address) {
	contractAddr := common.HexToAddress(contractAddress)
	parsedABI, err := abi.JSON(strings.NewReader(contractABI))
	if err != nil {
		log.Fatalf("Failed to parse contract ABI: %v", err)
	}

	// 调用合约的calculateReward方法
	rewardFnData, err := parsedABI.Pack("calculateReward", stakerAddress)
	if err != nil {
		log.Fatalf("Failed to pack calculateReward function data: %v", err)
	}

	callMsg := ethereum.CallMsg{
		To:   &contractAddr,
		Data: rewardFnData,
	}

	result, err := client.CallContract(context.Background(), callMsg, nil)
	if err != nil {
		log.Fatalf("Failed to call contract: %v", err)
	}

	var reward *big.Int
	err = parsedABI.UnpackIntoInterface(&reward, "calculateReward", result)
	if err != nil {
		log.Fatalf("Failed to unpack result: %v", err)
	}

	fmt.Printf("Reward Amount: %s PEPE\n", reward.String())
}
