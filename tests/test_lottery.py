from brownie import accounts, network, config
from brownie import lottery # type: ignore

def deployOn_TestNet(_new, _currentNetwork):
    
    if _new or _currentNetwork.startswith('mainnet-fork'):
        
        if _currentNetwork == 'avax-test':
            testAccount = accounts.load('dev-FujiAvalanche')
        elif _currentNetwork == 'sepolia':
            testAccount = accounts.load('dev-Sepolia')
        else:
            testAccount = accounts[0]
        
        deployedContract = lottery.deploy(config["networks"][_currentNetwork]['ethusd'],{"from": testAccount})
    else:
        testAccount = None
        deployedContract = lottery[-1]
    
    return deployedContract, testAccount
        
def test_getEntranceFee():
    Current_Network= network.show_active()  # type: ignore
    deployedContract, _ = deployOn_TestNet(_new=False, _currentNetwork=Current_Network)
    entranceCost = deployedContract.getEntranceFee()
    print("entranceCost is equal to:", entranceCost)
    print("Current **Estimated** ETH price: ", 50/(entranceCost/10**18)) # Validation: https://data.chain.link/feeds/ethereum/mainnet/eth-usd
    assert entranceCost >= 0.015*10**18
    
def test_rand():
    Current_Network= network.show_active()  # type: ignore
    deployedContract, ownerAccount = deployOn_TestNet(_new=True, _currentNetwork=Current_Network)
    randomNumber = deployedContract.randomNumCalc({"from": ownerAccount})
    print("Random Calculated Number:", randomNumber)
    assert randomNumber in range(100)