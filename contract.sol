// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";

/// @custom:security-contact adityapratapsingh51@gmail.com
contract OWASPToken is ERC2771Recipient, ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;

    mapping(uint => uint) public mintCounter;

    uint[] public winnerTeamIds;
    address[] public winnerAddresses;

    uint public teamCount;

    mapping(uint256 => string) dataURIs;

    Counters.Counter private _tokenIdCounter;

    string public defaultDataURI;

    bytes32 secret;

    constructor(address _trustedForwarder, bytes32 _secret) ERC721("OWASPToken", "OTK") {
        _setTrustedForwarder(_trustedForwarder);
        teamCount=10;
        defaultDataURI="ipfs://bafkreihaafbcz64qvrg5mwi3o67wxqhhopm7sguin6rgm4xsat2ydruwc4";
        secret=_secret;
    }

    modifier checkPassword(string memory password) {
        if (keccak256(abi.encodePacked(password)) != secret)
            revert();
        _;
    }

    function setSecret(bytes32 _secret) external onlyOwner {
        secret=_secret;
    }

    function setDefaultDataURI(string memory _defaultDataURI) external onlyOwner {
        defaultDataURI=_defaultDataURI;
    }

    function setTeamCount(uint _teamCount) external onlyOwner {
        teamCount=_teamCount;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (bytes(dataURIs[tokenId]).length != 0)
            return dataURIs[tokenId];
        return defaultDataURI;
    }

    function setTokenURI(uint256 tokenId, string memory uri) external onlyOwner {
        dataURIs[tokenId] = uri;
    }
    
    function setTrustedForwarder(address _trustedForwarder) public onlyOwner {
        _setTrustedForwarder(_trustedForwarder);
    }    

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(uint teamId, address to, string memory pass) public whenNotPaused checkPassword(pass) {
        if (teamId>teamCount)
            revert("teamId>teamCount");
        if (mintCounter[teamId] >= 3)
            revert("mintCounter[teamId] >= 3");
        if (mintCounter[teamId] == 0) {
            winnerTeamIds.push(teamId);
            winnerAddresses.push(_msgSender());
        }
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _msgSender() internal override(ERC2771Recipient, Context) virtual view returns (address ret) {
        return ERC2771Recipient._msgSender();
    }

    function _msgData() internal override(ERC2771Recipient, Context) view virtual returns (bytes calldata) {    
        return ERC2771Recipient._msgData();
    }

    function versionRecipient() external pure returns (string memory) {
        return "1";
    }    
}
