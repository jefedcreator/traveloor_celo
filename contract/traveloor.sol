//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Traveloor is ERC1155, Ownable{


    uint public price = 1;
    uint public premiumPrice = 0.3 ether;
    string uriHash = "ipfs://Qmcg2UE6pV3h8FXSH5LYs6BhxpKvEQ2EUi6Xugwt6VkN2y/";
    address public cUSDContractAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    mapping(uint => mapping(uint => bool)) sold;

    constructor() ERC1155("ipfs://Qmcg2UE6pV3h8FXSH5LYs6BhxpKvEQ2EUi6Xugwt6VkN2y") {
        // _mint(msg.sender, GOLD, 10**18, "");
        // _mint(msg.sender, SILVER, 10**27, "");
        // _mint(msg.sender, THORS_HAMMER, 1, "");
        // _mint(msg.sender, SWORD, 10**9, "");
        // _mint(msg.sender, SHIELD, 10**9, "");
        // cUSDContractAddress = _newAddress;
    }

    // modifier checkPrice() {
    //     require(IERC20Token(cUSDContractAddress).balanceOf(msg.sender) >= price, "insufficient balance");
    //     _;
    // }

    function checkPremium() internal view returns(bool) {
        for (uint256 i = 0; i <= 3; i++) {
            if(IERC1155(address(this)).balanceOf(msg.sender, i) >= 1){
                return true;
            }
        }
    }

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

    function updateHash(string memory _uriHash) public onlyOwner{
        uriHash = _uriHash;
    }

    function updatePrice(uint _price) public onlyOwner{
        price = _price;
    }

    function updatePremium(uint _premium) public onlyOwner{
        premiumPrice = _premium;
    }

    function mintNft(uint8 _type, uint8 _index) public {
        // require(_type <= 5, "nft volume exceeded");
        // require(_index <= 5, "nft volume exceeded");
        require(!sold[_type][_index], "nft has been sold");
        require(IERC20Token(cUSDContractAddress).transferFrom(msg.sender, address(this), price),"transfer failed");
        _setURI(uri(_type,_index));
        _mint(msg.sender, _type, 1,"");
        sold[_type][_index] = true;
    }

    function viewSold(uint8 _type, uint8 _index) public view returns(bool status){
        status = sold[_type][_index];
    }

    // function mintTrain() public checkPrice() payable{
    //     require(_trainIdCounter.current() <=5, "nft volume exceeded");
    //     uint tokenId = _trainIdCounter.current();
    //     _trainIdCounter.increment();
    //     _setURI(uri(TRAIN,tokenId));
    //     _mint(msg.sender, TRAIN, 1,"");
    // }

    // function mintCruise() public checkPrice() payable{
    //     require(_cruiseIdCounter.current() <= 5, "nft volume exceeded");
    //     uint tokenId = _cruiseIdCounter.current();
    //     _cruiseIdCounter.increment();
    //     _setURI(uri(CRUISE,tokenId));
    //     _mint(msg.sender, CRUISE, 1,"");
    // }

    // function mintHotel() public checkPrice() payable{
    //     require(_hotelIdCounter.current() <= 5, "nft volume exceeded");
    //     uint tokenId = _hotelIdCounter.current();
    //     _hotelIdCounter.increment();
    //     _setURI(uri(HOTEL,tokenId));
    //     _mint(msg.sender, HOTEL, 1,"");
    // }

    // function mintPremium() public payable{
    //     require(_premiumIdCounter.current() <= 5, "nft volume exceeded");
    //     require(msg.value == premiumPrice, "insufficient ether");
    //     require(checkPremium());
    //     uint tokenId = _premiumIdCounter.current();
    //     _premiumIdCounter.increment();
    //     _setURI(uri(PREMIUM,tokenId));
    //     _mint(msg.sender, PREMIUM, 1,"");
    // }
}