import Web3 from 'web3'
import { newKitFromWeb3 } from '@celo/contractkit'
import BigNumber from "bignumber.js"
import traveloorAbi from '../contract/traveloor.abi.json'
import erc20Abi from '../contract/erc20.abi.json'

const ERC20_DECIMALS = 18
const traveloorContractAddress = "0x0545bA7D01FaB97c3D113BE1Abc5787Db4F13B63"
const cUSDContractAddress = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1"

let kit
let contract
let products = []

const networks = {
    chainId : `0x${Number(44787).toString(16)}`,
    chainName: "Celo Alfajores Testnet",
    nativeCurrency: {
      name:"CELO",
      symbol:"CELO",
      decimals: 18
    },
    rpcUrls:["https://alfajores-forno.celo-testnet.org"],
    blockExplorerUrls:["https://alfajores-blockscout.celo-testnet.org"]
  }


const changeNetwork = async() =>{
  try {
    await ethereum.request({
      method: 'wallet_switchEthereumChain',
      params: [{ chainId: `0x${Number(44787).toString(16)}` }],
      
    });
    // window.location.reload();
  } catch (switchError) {
    // This error code indicates that the chain has not been added to MetaMask.
    if (switchError.code === 4902) {
      try {
        await ethereum.request({
          method: 'wallet_addEthereumChain',
          params: [
            networks
          ],
        });
      // window.location.reload();
      } catch (addError) {
        // handle "add" error
        notification(`⚠️ ${addError.message}.`)
      }
    }
    
  }
  // try {
  //   if (!window.ethereum) throw new Error(notification(`⚠️ ${"Metamask not found"}.`))
  //   await window.ethereum.request({
  //     method: "wallet_addEthereumChain",
  //     params:[
  //       networks
  //     ]
  //   });
  //   window.location.reload();
  // } catch (error) {
  //   notification(`⚠️ ${error.message}.`)
  // }
}

const connectCeloWallet = async function () {
    if (window.ethereum) {
      notification("⚠️ Please approve this DApp to use it.")
      try {
        await window.ethereum.enable()
        notificationOff()
        await changeNetwork()

        const web3 = new Web3(window.ethereum)
        kit = newKitFromWeb3(web3)
  
        const accounts = await kit.web3.eth.getAccounts()
        kit.defaultAccount = accounts[0]
  
        contract = new kit.web3.eth.Contract(traveloorAbi, traveloorContractAddress)

      } catch (error) {
        notification(`⚠️ ${error}.`)
      }
    } else {
      notification("⚠️ Please install the CeloExtensionWallet.")
    }
}

    const getBalance = async function () {
      try {
        const totalBalance = await kit.getTotalBalance(kit.defaultAccount)
        const cUSDBalance = totalBalance.cUSD.shiftedBy(-ERC20_DECIMALS).toFixed(2)
        document.querySelector("#balance").textContent = cUSDBalance
      } catch (error) {
        notification("⚠️ Please install the CeloExtensionWallet.")
      }
        
      }

  async function renderProducts() {
    document.getElementById("marketplace").innerHTML = ""
    products = await getNfts("https://ipfs.io/ipfs/Qmcg2UE6pV3h8FXSH5LYs6BhxpKvEQ2EUi6Xugwt6VkN2y");
    products.forEach((_product) => {
      const newDiv = document.createElement("div")
      newDiv.className = "col-md-3"
      newDiv.innerHTML = productTemplate(_product)
      document.getElementById("marketplace").appendChild(newDiv)
    })
}

const fetchNftMeta = async (ipfsUrl) => {
    try {
        if (!ipfsUrl) return null;
        const meta = await axios.get(ipfsUrl);
        return meta;
    } catch (e) {
        console.log({e});
    }
};

const getNfts = async (url) => {
    try {
        const nfts = [];
        for (let i = 1; i < 5; i++) {
           for (let j = 0; j < 5; j++) {
                const nft = new Promise(async (resolve) => {
                  
                    const res = `${url}/${i}/${j}.json`
                    const meta = await fetchNftMeta(res);
                    if (meta.status != 200) return;
            
                    const sold = await contract.methods.viewSold(i,j).call()
                    const price = await contract.methods.price().call()
                    resolve({
                        sold:sold,
                        price:Web3.utils.fromWei(price, 'ether'),
                        type: i,
                        index: j,
                        name: meta.data.name,
                        image: meta.data.image,
                        description: meta.data.description
                    });
                });
                nfts.push(nft);
            }
        }
        return Promise.all(nfts);
    } catch (e) {
        console.log({e});
    }
};



window.addEventListener('load', async () => {
    notification("⌛ Loading...")
    await connectCeloWallet()
    await getBalance()
    await renderProducts()
    notificationOff()
    // await showIPFSImage()
  });

function productTemplate(_product) {
    return `
      <div class="card mb-4">
        <img class="card-img-top" src="${_product.image}" alt="...">
        <div class="position-absolute top-0 end-0 bg-warning mt-4 px-2 py-1 rounded-start">
          ${returnStatus(_product.sold)}
        </div>
        <div class="card-body text-left p-4 position-relative">
        <div class="translate-middle-y position-absolute top-0">
        ${identiconTemplate(_product.owner)}
        </div>
        <h2 class="card-title fs-4 fw-bold mt-2">${_product.name}</h2>
        <p class="card-text mb-4" style="min-height: 82px">
          ${_product.description}             
        </p>
        <div class="d-grid gap-2">
          <a class="btn btn-lg btn-outline-dark buyBtn fs-6 p-3" id=${
            _product.index
          } data-id=${_product.type}>
            Buy for ${_product.price} cUSD
          </a>
        </div>
      </div>
    </div>
  `
}

function returnStatus(status){
  if (!status) return "available";
  return "sold";
}

async function approve(_price) {
  const cUSDContract = new kit.web3.eth.Contract(erc20Abi, cUSDContractAddress)

  const result = await cUSDContract.methods
    .approve(traveloorContractAddress, _price)
    .send({ from: kit.defaultAccount })
  return result
}

document.querySelector("#marketplace").addEventListener("click", async function buyNft (e){
  if (e.target.className.includes("buyBtn")) {
    const index = Number(e.target.id)
    const type = Number(e.target.dataset['id'])
    const product = Number(getIndex(type,index))
    console.log("product is:",product);
    notification("⌛ Waiting for payment approval...")
    try {
      await approve("100000000000000000000")
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
    try {
      notification(`⌛ Awaiting payment for one"${products[product].description}"...`)
      await contract.methods.mintNft(type,index).send({from:kit.defaultAccount})
      notification(`🎉 You successfully bought one"${products[product].description}".`)
      renderProducts()
      getBalance()
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  }
})

function getIndex(type,index){
  return type * 5 + index; 
}

function identiconTemplate(_address) {
    const icon = blockies
      .create({
        seed: _address,
        size: 8,
        scale: 16,
      })
      .toDataURL()
  
    return `
    <div class="rounded-circle overflow-hidden d-inline-block border border-white border-2 shadow-sm m-0">
      <a href="https://alfajores-blockscout.celo-testnet.org/address/${_address}/transactions"
          target="_blank">
          <img src="${icon}" width="48" alt="${_address}">
      </a>
    </div>
    `
  }

  function notification(_text) {
    document.querySelector(".alert").style.display = "block"
    document.querySelector("#notification").textContent = _text
  }
  
  function notificationOff() {
    document.querySelector(".alert").style.display = "none"
  }

  // window.addEventListener("load", () => {
  //   notification("⌛ Loading...")
  //   notificationOff()
  // })

  document
  .querySelector("#newProductBtn")
  .addEventListener("click",async () => {
    const owner = await contract.methods.deployer.call()
    if(owner != kit.defaultAccount) notification(`⚠️ only ticket seller can update details`)
    const name = document.getElementById("newProductName").value;
    const image = document.getElementById("newImgUrl").value;
    await contract.methods.updateHash(name).send({from:kit.defaultAccount})
    await contract.methods.updatePrice(Web3.utils.toWei(image, 'ether')).send({from:kit.defaultAccount})
    notification(`🎉 You have updated tickets succesfully".`)
    renderProducts()
  })