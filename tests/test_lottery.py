from brownie import accounts, network, config
from brownie import lottery, interface # type: ignore
import pytest

LOTTERY_STATES = {
        'OPEN': 0,
        'CLOSED': 1,
        'CALCULATING_WINNER': 2,
    }

def autoAccount(_currentNetwork):
    if _currentNetwork == 'avax-test':
        testAccount = accounts.load('dev-FujiAvalanche')
    elif _currentNetwork == 'sepolia':
        testAccount = accounts.load('dev-Sepolia')
    else:
        testAccount = accounts[0]
    return testAccount
    
def deployOn_TestNet(_new, _currentNetwork):
    
    if _new or _currentNetwork.startswith('mainnet-fork'):
        testAccount = autoAccount(_currentNetwork)
        # deployedContract = lottery.deploy(config["networks"][_currentNetwork]['ethusd'],{"from": testAccount})
        try:
            deployedContract = lottery.deploy(1000000,
                                              config["networks"][_currentNetwork]['ethusd'],
                                              config["networks"][_currentNetwork]["wrapper"],
                                              config["networks"][_currentNetwork]["link"], 
                                              {"from": testAccount}
                                              )
        #*** Sepolia (INFURA) needs VPN in Iran
        except Exception as e:
            print(f"Deployment failed: {e}")
    else:
        testAccount = autoAccount(_currentNetwork)
        deployedContract = lottery[-1]
    
    return deployedContract, testAccount

def fund_with_LINK(ContractAddress, _account=None, linkTokenAddress=None, amount=2*10**18, _NetWork=network.show_active() ): # type: ignore
    # 7:42
    account = _account if _account else autoAccount(_NetWork)
    LinkToken = interface.LinkTokenInterface(linkTokenAddress)
    Txn = LinkToken.transfer(ContractAddress, amount, {"from": account})
    Txn.wait(1)
        
def test_getEntranceFee():
    Current_Network= network.show_active()  # type: ignore
    deployedContract, _ = deployOn_TestNet(_new=True, _currentNetwork=Current_Network)
    entranceCost = deployedContract.getEntranceFee()
    print("entranceCost is equal to:", entranceCost)
    print("Current **Estimated** ETH price: ", 50/(entranceCost/10**18)) 
    # Validation: https://data.chain.link/feeds/ethereum/mainnet/eth-usd
    assert entranceCost >= 0.015*10**18
    
def test_rand():
    Current_Network= network.show_active()  # type: ignore
    deployedContract, ownerAccount = deployOn_TestNet(_new=False, _currentNetwork=Current_Network)
    randomNumber = deployedContract.randomNumCalc({"from": ownerAccount})
    # Do NOT forget {"from": ownerAccount} when ever you gonna call this func using brownie
    print("Random Calculated Number:", randomNumber)
    assert randomNumber in range(100)
    
def test_Functionality():
    # pytest.skip("Not Yet")
    # Arrange:
    Current_Network= network.show_active()  # type: ignore
    deployedContract, ownerAccount = deployOn_TestNet(_new=True, _currentNetwork=Current_Network)
    print('deployedContract Address: ', deployedContract.address)
    
    # Act:
    if deployedContract.lotteryState() == 1:
        print("Starting Lottery ...")
        deployedContract.startLottery({"from": ownerAccount})
    
    print("Entering Lottery: ")
    entranceCost = deployedContract.getEntranceFee()
    deployedContract.enter({"from": ownerAccount, "value": entranceCost+100})
    print("Number of Players: ", deployedContract.getPlayersCount())
    
    print("Charging Link Token ...") # 8:11:00
    print("Balance Before: ", deployedContract.getLinkBalance())
    fund_with_LINK(deployedContract.address, ownerAccount, config["networks"][Current_Network]["link"], 2*10**18, Current_Network)
    print("Balance After: ", deployedContract.getLinkBalance())
    
    Txn = deployedContract.endLottery({"from": ownerAccount, "gas_limit": 500000})
    Txn.wait(1)
    print("Lottery Ended, Calculating the Winner.")
    assert deployedContract.lotteryState() == LOTTERY_STATES["CALCULATING_WINNER"]
    print("Remained Balance: ", deployedContract.getLinkBalance())
    
    print("withdrawing Link ...")
    Txn = deployedContract.withdrawLink({"from": ownerAccount})
    Txn.wait(5)
    print("Link Balance: ", deployedContract.getLinkBalance())
    
    print("s_requests[reqID]: ", deployedContract.s_requests(deployedContract.lastRequestId()))
    if deployedContract.s_requests(deployedContract.lastRequestId())[1]:
        print("myRand: ", deployedContract.myRand(0), deployedContract.myRand(1))
    print("Winner: ", deployedContract.Winner())
    # Assert: