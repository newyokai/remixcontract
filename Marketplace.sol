// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/IERC721.sol';

contract Marketplace {

    event CreatedAuction (uint256 _tokenId, uint256 _startPrice);
    event Bid(address indexed sender, uint256 amount);
    event Withdraw(address indexed bidder, uint256 amount);
    event End(address highestBidder, uint256 amount);
    event CreatedSell(address indexed seller, uint256 amount);
    event Sold(address indexed buyer, uint256 amount);

    IERC721 private Yokai;
    address private owner;

    struct Auction {
        address seller;
        uint256 endAt;
        
        address highestBidder;
        uint256 highestBid;
        uint256 bidCount;
    }

    struct Sell {
        address seller;
        uint256 price;
    }

    mapping(uint256 => Sell) tokensForSale;
    mapping(uint256 => Auction) tokensInAuction;
    mapping(address => uint) bids;
    
    constructor () {
        owner=msg.sender;
    }

    function test(address receiver) public payable {
        payable(receiver).transfer(msg.value);
    }

    function createSell(uint256 _tokenId, uint256 _price) public {
        require(isFree(_tokenId), "Token in auction or sell");
        require(msg.sender==Yokai.ownerOf(_tokenId), "Not owner");
        require(_price>0, "Price must be >0");
        require(isAllowed(), "You have to allowed this contract");
        

        Sell memory sell = Sell(msg.sender,_price);
        
        Yokai.transferFrom(msg.sender, address(this), _tokenId);

        tokensForSale[_tokenId]=sell;

        emit CreatedSell(msg.sender, _price);
    }

    function getSeller(uint256 _tokenId) public view returns(address){
        require(!notForSale(_tokenId));
        Sell memory sell = tokensForSale[_tokenId];
        return sell.seller;
    }

    function getPrice(uint256 _tokenId) public view returns(uint256){
        require(!notForSale(_tokenId));
        Sell memory sell = tokensForSale[_tokenId];
        return sell.price;
    }

    function createAuction(uint256 _tokenId, uint256 _startPrice, uint256 _time) public {
        require(msg.sender==Yokai.ownerOf(_tokenId), "Not the owner");
        require(_startPrice>=0, "Start price must be equal or higher than zero");
        require(isFree(_tokenId), "Token already in auction or sell");
        require(isAllowed(), "Contract not allowed to manage your token");
        uint256 time = block.timestamp +  _time;
        Auction memory auction = Auction(msg.sender, time, address(0), _startPrice, 0);

        Yokai.transferFrom(msg.sender, address(this), _tokenId);

        tokensInAuction[_tokenId]=auction;

        emit CreatedAuction(_tokenId, _startPrice);
    }

    function cancelSell(uint256 _tokenId) public {
        require(!notForSale(_tokenId));
        require(msg.sender == tokensForSale[_tokenId].seller);
        Yokai.transferFrom(address(this), msg.sender, _tokenId);
        tokensForSale[_tokenId]=resetSell();
    }

    function bid(uint256 _tokenId) public payable {
        require(!notInAuction(_tokenId), "Not in auction");
        //require(!isEnded(_tokenId), "Auction ended");
        require(msg.sender != tokensInAuction[_tokenId].seller, "Seller can't do offer");
        require(msg.sender != tokensInAuction[_tokenId].highestBidder, "Highest bidder can't do offer");
        require(msg.value+bids[msg.sender] > tokensInAuction[_tokenId].highestBid, "Bid too low");
        uint256 bidsBySender = bids[msg.sender];
        bids[msg.sender] = 0;
        Auction storage auction = tokensInAuction[_tokenId];
        //If we have 0 offers
        if(auction.highestBidder!=address(0)) {
            bids[auction.highestBidder]=auction.highestBid;
        }

        auction.highestBid=msg.value+bidsBySender;
        auction.highestBidder=msg.sender;
        auction.bidCount+=1;
        emit Bid(msg.sender, msg.value);
    }

    function buy(uint256 _tokenId) public payable {
        require(!notForSale(_tokenId), 'Not for sale');
        require(msg.value == tokensForSale[_tokenId].price, 'Not right value');
        require(msg.sender != tokensForSale[_tokenId].seller, 'You are the seller');

        uint256 bal = msg.value;
        address payable seller = payable(tokensForSale[_tokenId].seller);
        seller.transfer(bal);
        Yokai.transferFrom(address(this), msg.sender, _tokenId);

        tokensForSale[_tokenId]=resetSell();

        emit Sold(msg.sender, msg.value);
    }

    function endAuction(uint _tokenId) public {
        require(!notInAuction(_tokenId), "Not in auction");
        require(isEnded(_tokenId), "Not ended yet");

        Auction memory auction = tokensInAuction[_tokenId];

        if(auction.highestBidder!=address(0)) {
            Yokai.transferFrom(address(this), auction.highestBidder, _tokenId);
            payable(auction.seller).transfer(auction.highestBid);
        } else {
            Yokai.transferFrom(address(this), auction.seller, _tokenId);
        }
        address winner = auction.highestBidder;
        uint256 amount = auction.highestBid;
        tokensInAuction[_tokenId] = resetAuction();
        
        emit End(winner, amount);
    }

    function withdraw() public {
        require(bids[msg.sender]>0);
        uint256 bal = bids[msg.sender];
        bids[msg.sender]=0;
        payable(msg.sender).transfer(bal);
        emit Withdraw(msg.sender,bal);
    }

    function getAuctionData (uint256 _tokenId) public view returns(Auction memory) {
        require(!notInAuction(_tokenId));
        return tokensInAuction[_tokenId];
    }

    function getSellData (uint256 _tokenId) public view returns(Sell memory) {
        require(!notForSale(_tokenId));
        return tokensForSale[_tokenId];
    }

    function notInAuction (uint256 _tokenId) public view returns(bool) {
        Auction memory auction = tokensInAuction[_tokenId];
        return auction.seller==address(0);
    }

    function notForSale (uint256 _tokenId) public view returns(bool) {
        Sell memory sell = tokensForSale[_tokenId];
        return sell.seller==address(0);
    }

    function getEndTime(uint256 _tokenId) public view returns(uint256) {
        require(!notInAuction(_tokenId), 'Token not in auction');
        Auction memory auction = tokensInAuction[_tokenId];
        return auction.endAt;
    }

    function isFree(uint256 _tokenId) public view returns(bool) {
        return (notInAuction(_tokenId) && notForSale(_tokenId));
    }

    function isEnded(uint256 _tokenId) public view returns (bool) {
        require(!notInAuction(_tokenId));
        Auction memory auction = tokensInAuction[_tokenId];
        return auction.endAt<block.timestamp;       
    }

    
    function isAllowed() public view returns(bool) {
        return Yokai.isApprovedForAll(msg.sender, address(this));
    }

    function resetAuction() internal pure returns(Auction memory) {
        Auction memory auction = Auction(address(0), 0, address(0), 0, 0);
        return auction;
    }

    function resetSell() internal pure returns(Sell memory) {
        Sell memory sell = Sell(address(0),0);
        return sell;
    }

    function load() public payable {
        
    }

    function setAddress (address nftAddress) public OnlyOwner {
        Yokai = IERC721(nftAddress);
    }

    function setOwner(address newOwner) public OnlyOwner {
        owner=newOwner;
    }

    modifier OnlyOwner {
        require(msg.sender==owner);
        _;
    }

}
