// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./YokaiCore.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract YokaiManager is YokaiCore {

    ERC20 Seki;
    address YokaiManagerOwner;

    constructor(address _seki, address _yokaigateway) YokaiCore(_yokaigateway) {
        Seki = ERC20(_seki);
        YokaiManagerOwner = msg.sender;
    }

    function setSekiAddress (address _newAddress) public OnlyOwner {
        Seki = ERC20(_newAddress);
    } 

    function passOwnership (address _newAddress) public OnlyOwner {
        YokaiManagerOwner = _newAddress;
    }

    function increaseStats(uint256 tokenId, uint8[] memory statsToIncrease) public payable returns(bool) {
        require(msg.sender == ownerOf(tokenId));
        require(increaseIsPossible(statsToIncrease, yokai[tokenId].statistics));
        uint256 amount = increaseTotalCalculator(statsToIncrease,yokai[tokenId].statistics);
        require(Seki.balanceOf(msg.sender)>=amount);
        require(Seki.allowance(msg.sender,address(this))>=amount);
        Seki.transferFrom(msg.sender, address(this), amount );
        _increaseYokaiStats(tokenId, statsToIncrease);
        return true;
    }

    function _increaseYokaiStats(uint256 _tokenId, uint8[] memory _statsToIncrease) internal returns(bool) {
        for(uint8 x = 0; x<_statsToIncrease.length; x++) {
            if(_statsToIncrease[x]==0) continue;
            yokai[_tokenId].statistics[x] = _statsToIncrease[x];
        }
        return true;
    }

    function increaseIsPossible (uint8[] memory _increaseStats, uint8[6] memory _baseStats) internal pure returns(bool) {
        uint8 max = 153;
        uint8 total = 0;
        for(uint8 x = 0; x < 6; x++) {
            if(_increaseStats[x]==0) {
                total += _baseStats[x];
                continue;
            }
            total += _increaseStats[x];
        }
        return total <= max;
    }

    function increaseTotalCalculator(uint8[] memory statsList, uint8[6] memory baseStats) public pure returns(uint256) {
        
        uint256 sekiRequests = 0;

        for (uint256 x = 0; x<statsList.length; x++) {
            if(statsList[x]==0 || statsList[x]==baseStats[x]) continue;
            uint256 total = requestedSeki(baseStats[x], statsList[x]);
            sekiRequests += total;
        }

        return sekiRequests;
    }

    function requestedSeki(uint8 from, uint8 to) public pure returns (uint256) {
        require(from>=1 && to<=50 && from<to);
        uint256 totalRequested = 0;
        for (uint x = from; x<to; x++) {
            uint256 requestToIncrease = sekiToUpgrade(x);
            totalRequested += requestToIncrease;
        }
        return totalRequested;
    }   

    function sekiToUpgrade(uint256 value) public pure returns(uint256 seki) {
        require(value>=1 && value<50);
        if(value>=1 && value<10) return 2;
        if(value>=10 && value<20) return 3;
        if(value>=20 && value<30) return 4;
        if(value>=30 && value<40) return 5;
        if(value>=40 && value<50) return 6;
    }

    modifier OnlyOwner {
        require(msg.sender == YokaiManagerOwner);
        _;
    }

}
