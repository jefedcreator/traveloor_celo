//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20Token {
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);
}

contract Traveloor is ERC1155, Ownable{
    uint public price = 1;
    uint public premiumPrice = 0.3 ether;
    string uriHash = "ipfs://Qmcg2UE6pV3h8FXSH5LYs6BhxpKvEQ2EUi6Xugwt6VkN2y/";
    address cUSDContractAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;
    address public deployer;

    mapping(uint => mapping(uint => bool)) sold;

    ///@notice the construtor initializes the ERC1155 contract with the global uriHash variable. also sets the deployer address.
    constructor() ERC1155(uriHash) {
        deployer = msg.sender;
    }

    ///@notice uri internal function returns a new uri from its arguments whenever it is called. this helps platforms like opensea visualize each ERC1155 token
    ///@param _type refers to the type of NFT contained within this ERC1155
    ///@param _index refers to a specific NFT of a certain type
    function uri(uint collectionId, uint tokenId ) internal view returns(string memory){
        return (
            string(
                abi.encodePacked(uriHash,
                Strings.toString(collectionId),
                "/",
                Strings.toString(tokenId),
                ".json"
                )
            )
        ); 
    }

    ///@notice updateHash function updates the uriHash global variable
    function updateHash(string memory _uriHash) public onlyOwner{
        uriHash = _uriHash;
    }

    ///@notice updatePrice function updates the price global variable
    function updatePrice(uint _price) public onlyOwner{
        price = _price;
    }

    ///@notice updatePremium function updates the premiumPrice global variable
    function updatePremium(uint _premium) public onlyOwner{
        premiumPrice = _premium;
    }

    ///@param _type refers to the type of NFT contained within this ERC1155
    ///@param _index refers to a specific NFT of a certain type
    ///@notice mintNft function mint one ERC1155 nft as specified within its parameters, for a specific cUSD cost
    function mintNft(uint8 _type, uint8 _index) public {
        require(IERC20Token(cUSDContractAddress).balanceOf(msg.sender) >= price, "insufficient balance");
        require(!sold[_type][_index], "nft has been sold");
        require(IERC20Token(cUSDContractAddress).transferFrom(msg.sender, address(this), price),"transfer failed");
        _setURI(uri(_type,_index));
        _mint(msg.sender, _type, 1,"");
        sold[_type][_index] = true;
    }

    ///@param _type refers to the type of NFT contained within this ERC1155
    ///@param _index refers to a specific NFT of a certain type
    ///@return this function returns the status of each NFT through a nested mapping
    function viewSold(uint8 _type, uint8 _index) public view returns(bool status){
        status = sold[_type][_index];
    }
}