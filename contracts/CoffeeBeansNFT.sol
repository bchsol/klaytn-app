// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@klaytn/contracts/contracts/KIP/token/KIP17/extensions/KIP17Enumerable.sol";
import "@klaytn/contracts/contracts/access/Ownable.sol";
import "@klaytn/contracts/contracts/utils/Strings.sol";

contract CoffeeBeansNFT is KIP17Enumerable, Ownable{
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public maxSupply = 40;
    uint256 public maxMintAmount = 3;
    uint256 public mintPrice = 0;  // Klay
    uint256 public nftPerAddressLimit = 1;
    bool public paused = false;

    bool public revealed = true;
    string public notRevealedUri;

    bool public onlyWhitelisted = false;
    mapping(address=>bool) private WhitelistAddress;
    mapping(address=>uint256) public addressMintedBalance;
    mapping(address=>uint) public addressTimedlay;

    event Klaytn17Burn(address _to, uint256 tokenId);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    )   
        KIP17(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

     function _baseURI() internal view override returns (string memory) {
         return baseURI;
    }

    // public
    function mint(address _to, uint256 _mintAmount) public payable {
        require(!paused, "the contract is paused");
        
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1");
        require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        if(msg.sender != owner()){
            if(onlyWhitelisted == true) {
                require(WhitelistAddress[msg.sender],"user is not Whitelist");
                uint256 ownerMintedCount = addressMintedBalance[msg.sender];
                require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
            }
            require(msg.value >= mintPrice * _mintAmount, "insufficient funds");

            if(addressTimedlay[msg.sender] == 0){
                addressTimedlay[msg.sender] = block.timestamp;
            }else{
                require(block.timestamp >= (addressTimedlay[msg.sender] + 5 seconds), "false");
                addressTimedlay[msg.sender] = block.timestamp;
            }
        }

        for(uint256 i = 1; i <= _mintAmount; i++){
            addressMintedBalance[msg.sender]++;
            _safeMint(_to, supply + i);
        }
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory){
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        
        for(uint256 i; i < tokenCount; i++){
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory){
        require(_exists(tokenId), "KIP17 metadata: URI query for nonexistent token");

        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        string memory idstr;

        uint256 temp = tokenId;
        idstr = Strings.toString(temp);

        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, idstr, baseExtension)) : "";
    }

    // onlyOwner
    function setCost(uint256 _newMintPrice) public onlyOwner() {
        mintPrice = _newMintPrice;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
        maxMintAmount = _newmaxMintAmount;
    }

    function setWhitelistLimit(uint256 _newLimit) public onlyOwner {
        nftPerAddressLimit = _newLimit;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function addWhitelist(address user) public onlyOwner {
        WhitelistAddress[user] = true;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }
    
    function withdraw(address payable toAdress) public onlyOwner {
        toAdress.transfer(address(this).balance);
    }
}