// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import './MinterGateway.sol';

contract Seki is ERC20, MinterGateway {
    constructor (address _gatewayAddress) ERC20 ("Seki", "SEKI") MinterGateway(_gatewayAddress) {}

    function mint(uint _amount, uint _nonce, bytes memory _signature) public {
        require(verify(gatewayAddress, msg.sender, _amount,"Claiming SEKI", _nonce, _signature));
        require(!executed[_signature]);
        executed[_signature] = true;
        _mint(msg.sender,_amount);
    }
    
    function testMint(uint _amount) public {
        _mint(msg.sender,_amount);
    }
   
}   
