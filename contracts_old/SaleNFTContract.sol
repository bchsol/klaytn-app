pragma solidity ^0.5.6;

import "./nftMintContract.sol";

contract SaleForNFTContract {
    
    TestNFT public mintContractAddress;
    mapping(uint256 => uint256) public tokenPrices; // (수정필요)

    constructor (address _mintContractAddress) public {
        mintContractAddress = TestNFT(_mintContractAddress);    // NFT 컨트랙트
    }

    // 판매중인 NFT 배열
    uint256[] public onSaleTokenArray;

    // 판매
    function setForSaleNFT(uint256 _tokenId, uint256 _price) public {
        // NFT소유자의 주소를 가져옴
        address tokenOwner = mintContractAddress.ownerOf(_tokenId);

        // 호출자와 소유자가 같은지
        require(tokenOwner == msg.sender, "Caller is not Token Owner");
        // 가격이 0이상인지
        require(_price > 0, "Price is zero");
        // 판매중인 NFT인지
        require(tokenPrices[_tokenId] == 0, "This token is already on sale");
        // NFT소유자에게 권한을 위임받았는지
        require(mintContractAddress.isApprovedForAll(tokenOwner, address(this)), "Token owner did not approve token");

        tokenPrices[_tokenId] = _price;

        onSaleTokenArray.push(_tokenId);
    }

    // 구매
    function purchaseToken(uint256 _tokenId) public payable {
        uint256 price = tokenPrices[_tokenId];

        // Casting from address to address payable
        // address addr1 = msg.sender
        // address payable addr2 = address(uint160(addr1)) // Solidity >= 0.5.0
        // address payable addr3 = payable(addr1) >= 0.6.0
        address payable tokenOwner = address(uint160(mintContractAddress.ownerOf(_tokenId)));

        // 판매중인 NFT인지
        require(price > 0, "token not sale.");
        // 호출자의 자산이 가격보다 많은지
        require(price <= msg.value, "Caller sent lower than value.");
        // NFT소유자와 호출자가 다른지
        require(tokenOwner != msg.sender, "Caller is token owner");

        // NFT를 구매자에게 넘겨줌
        tokenOwner.transfer(msg.value);
        mintContractAddress.safeTransferFrom(tokenOwner, msg.sender, _tokenId);

        tokenPrices[_tokenId] = 0;

        // 판매 배열 정리(수정필요)
        for(uint256 i = 0; i < onSaleTokenArray.length; i++) {
            if(tokenPrices[onSaleTokenArray[i]] == 0) {
                onSaleTokenArray[i] = onSaleTokenArray[onSaleTokenArray.length - 1];
                onSaleTokenArray.pop();
            }
        }
    }

    // 판매중인 NFT 갯수
    function getOnSaleTokenArrayLength() view public returns (uint256) {
        return onSaleTokenArray.length;
    }
}