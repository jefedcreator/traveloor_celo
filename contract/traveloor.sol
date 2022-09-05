//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20Token {
    function transfer(address, uint256) external returns (bool);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Traveloor is ERC1155, Ownable {
    uint public price = 1;
    string public uriHash =
        "ipfs://Qmcg2UE6pV3h8FXSH5LYs6BhxpKvEQ2EUi6Xugwt6VkN2y/";
    address public cUSDContractAddress =
        0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    mapping(uint => mapping(uint => bool)) sold;
    mapping(uint => string) private _uris;

    constructor()
        ERC1155("ipfs://Qmcg2UE6pV3h8FXSH5LYs6BhxpKvEQ2EUi6Xugwt6VkN2y")
    {}

    /**
     * @dev sets uri for Token with collectionID in the format baseUri(uriHash)/_id.json
     *
     */
    function createTokenUri(uint collectionId)
        internal
        view
        returns (string memory)
    {
        return (
            string(
                abi.encodePacked(
                    uriHash,
                    Strings.toString(collectionId),
                    ".json"
                )
            )
        );
    }

    /**
     * @dev allows the contract's owner to update the base URI
     * @param _uriHash the new base URI
     */
    function updateHash(string calldata _uriHash) public onlyOwner {
        uriHash = _uriHash;
        _setURI(_uriHash);
    }

    /**
     * @dev allow the contract's owner to update the price for minting
     * @param _price the new price
     */
    function updatePrice(uint _price) public onlyOwner {
        price = _price;
    }

    /**
     * @dev allow users to mint an NFT
     * @param _type ID of token
     * @param _index ID of _type's token to mint
     */
    function mintNft(uint8 _type, uint8 _index) public {
        require(!sold[_type][_index], "nft has been sold");
        if (bytes(_uris[_type]).length == 0) {
            _uris[_type] = createTokenUri(_type);
        }
        _mint(msg.sender, _type, 1, "");
        sold[_type][_index] = true;
        require(
            IERC20Token(cUSDContractAddress).transferFrom(
                msg.sender,
                address(this),
                price
            ),
            "transfer failed"
        );
    }

    /**
     * @return status of whether a token of _type with _index has been minted/bought
     * @param _type ID of token
     * @param _index ID of _type's token to mint
     */
    function viewSold(uint8 _type, uint8 _index)
        public
        view
        returns (bool status)
    {
        status = sold[_type][_index];
    }

    /**
     * @dev returns the uri for token with type _id
     This have been overriden to return the specific uri for each token type instead of the baseUri
    */
    function uri(uint256 _id)
        public
        view
        virtual
        override(ERC1155)
        returns (string memory)
    {
        return _uris[_id];
    }
}
