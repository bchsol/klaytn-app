pragma solidity ^0.5.6;

import "./nftMintContract.sol";

contract SaleForNFTContract {
    
    TestNFT public mintContractAddress;
    mapping(uint256 => uint256) public tokenPrices;

    constructor (address _mintContractAddress) public {
        mintContractAddress = TestNFT(_mintContractAddress);
    }

    uint256[] public onSaleTokenArray;

    function setForSaleNFT(uint256 _tokenId, uint256 _price) public {
        address tokenOwner = mintContractAddress.ownerOf(_tokenId);

        require(tokenOwner == msg.sender, "Caller is not Token Owner");
        require(_price > 0, "Price is zero");
        require(tokenPrices[_tokenId] == 0, "This token is already on sale");
        require(mintContractAddress.isApprovedForAll(tokenOwner, address(this)), "Token owner did not approve token");

        tokenPrices[_tokenId] = _price;

        onSaleTokenArray.push(_tokenId);
    }

    function purchaseToken(uint256 _tokenId) public payable {
        uint256 price = tokenPrices[_tokenId];

        // Casting from address to address payable
        // address addr1 = msg.sender
        // address payable addr2 = address(uint160(addr1)) // Solidity >= 0.5.0
        // address payable addr3 = payable(addr1) >= 0.6.0
        address payable tokenOwner = address(uint160(mintContractAddress.ownerOf(_tokenId)));

        require(price > 0, "token not sale.");
        require(price <= msg.value, "Caller sent lower than value.");
        require(tokenOwner != msg.sender, "Caller is token owner");


        tokenOwner.transfer(msg.value);
        mintContractAddress.safeTransferFrom(tokenOwner, msg.sender, _tokenId);

        tokenPrices[_tokenId] = 0;

        for(uint256 i = 0; i < onSaleTokenArray.length; i++) {
            if(tokenPrices[onSaleTokenArray[i]] == 0) {
                onSaleTokenArray[i] = onSaleTokenArray[onSaleTokenArray.length - 1];
                onSaleTokenArray.pop();
            }
        }
    }

    function getOnSaleTokenArrayLength() view public returns (uint256) {
        return onSaleTokenArray.length;
    }
}