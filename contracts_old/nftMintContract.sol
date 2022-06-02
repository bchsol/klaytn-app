pragma solidity ^0.5.6;

import "./token/KIP17/KIP17Full.sol";
import "./token/KIP17/KIP17Burnable.sol";
import "./ownership/Ownable.sol";
import "./utils/String.sol";

contract TestNFT is KIP17Full, KIP17Burnable, Ownable{
    using String for uint256;
    string public baseURI;     // Image URI
    string public baseExtension = ".json";  // Image file format
    uint256 public maxSupply = 99;
    uint256 public maxMintAmount = 10;       // Public Mint Limit
    uint256 public cost;  // Klay
    uint256 public nftPerAddressLimit = 1;  // Whitelist Mint Limit
    bool public paused = false;     // Mint Pause

    bool public revealed = false;
    string public notRevealedUri;

    bool public onlyWhitelisted = false;
    mapping(address=>bool) private WhitelistAddress;    // 화이트리스트 지갑 주소
    mapping(address=>uint256) public addressMintedBalance;  // 지갑별 민팅한 갯수
    mapping(address=>uint) public addressTimedlay;  // 지갑별 트랜잭션 딜레이

    event Klaytn17Burn(address _to, uint256 tokenId);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    )   
        KIP17Burnable()
        KIP17Full(_name, _symbol) public {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

     function _baseURI() internal view returns (string memory) {
         return baseURI;
    }

    // public
    function mint(address _to, uint256 _mintAmount) public payable {
        // 중지중일때
        require(!paused, "the contract is paused");
        
        uint256 supply = totalSupply();
        // 민팅갯수가 0보다 많은지
        require(_mintAmount > 0, "need to mint at least 1");
        // 민팅갯수가 최대민팅갯수를 넘는지
        require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
        // 현재까지 발행량 + 민팅갯수가 최대 발행량을 넘는지
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        if(msg.sender != owner()){
            // 화이트 리스트만 민팅 진행
            if(onlyWhitelisted == true) {
                // 화이트리스트에 들어가있는지 bool형으로 체크
                require(WhitelistAddress[msg.sender],"user is not Whitelist");
                // 주소별 민팅 갯수를 저장
                uint256 ownerMintedCount = addressMintedBalance[msg.sender];
                // 민팅한 갯수 + 민팅하려는 갯수 <= 지갑별 민팅 제한갯수
                require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
            }
            // 호출자의 자산(Klay)이 민팅 비용보다 많은지
            require(msg.value >= cost * _mintAmount, "insufficient funds");

            // 민팅 시 5초 딜레이
            if(addressTimedlay[msg.sender] == 0){
                // 주소별로 호출시간을 저장
                addressTimedlay[msg.sender] = now;
            }else{
                // 현재시간이 이전 호출시간보다 5초 지났을때
                require(now >= (addressTimedlay[msg.sender] + 5 seconds), "false");
                addressTimedlay[msg.sender] = now;
            }
        }

        // id start no.1
        for(uint256 i = 1; i <= _mintAmount; i++){
            addressMintedBalance[msg.sender]++;
            _safemint(_to, supply + i,"");
        }
    }

    // 지갑에 있는 토큰들을 보여줌
    function walletOfOwner(address _owner) public view returns(uint256[] memory){
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        
        for(uint256 i; i < tokenCount; i++){
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    // NFT의 URI 정보를 보여줌
    function tokenURI(uint256 tokenId) public view returns(string memory){
        require(_exists(tokenId), "KIP17 metadata: URI query for nonexistent token");

        // 리빌을 안했을시
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        string memory idstr;

        uint256 temp = tokenId;
        idstr = String.uint2str(temp);

        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, idstr, baseExtension)) : "";
    }

    function _safemint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnKIP17Received(address(0), to, tokenId, _data), "KIP17: transfer to non KIP17Receiver implementer");
    }

    // NFT소각
    function burnSingle(uint256 _tokenId) public {
        burn(_tokenId);
        emit Klaytn17Burn(msg.sender, _tokenId);
    }

    // onlyOwner
    // 민팅 비용 
    function setCost(uint256 _newCost) public onlyOwner() {
        cost = _newCost;
    }

    // 최대 민팅 갯수
    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
        maxMintAmount = _newmaxMintAmount;
    }

    // 화이트리스트 최대 민팅 갯수
    function setWhitelistLimit(uint256 _newLimit) public onlyOwner {
        nftPerAddressLimit = _newLimit;
    }

    // 리빌전 URI
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    // 리빌 후 URI
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    // 기본 .json
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    // 화이트리스트만 민팅
    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    // 민팅 일시중지
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    // 화이트리스트 주소 추가
    function addWhitelist(address user) public onlyOwner {
        WhitelistAddress[user] = true;
    }

    // 리빌
    function reveal() public onlyOwner {
        revealed = true;
    }

    // 출금
    function withdraw(address payable toAdress) public onlyOwner {
        toAdress.transfer(address(this).balance);
    }
}