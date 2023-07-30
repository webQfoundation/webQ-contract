// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./safe/Safe.sol";
import "./qrc/QRC20/QRC20.sol";

contract WebQ is Safe, QRC20 {

    event Donation(address donor, uint256 amount);

    receive() external payable override {
        if (msg.value> 0) {
            emit Donation(msg.sender, msg.value);
        }
    }

    function _afterQRC(uint256 Q_address, bytes memory Q_message, bytes calldata Q_signature) override internal {
        Q_address;
        Q_message;
        Q_signature;
        if (msg.value> 0) {
            emit Donation(msg.sender, msg.value);
        }
    }

    function mintQRC(uint256 totalSupply, uint256 Q_address, uint256 nonce, uint256 value) pure external override returns (uint256 amount){
        
        Q_address;
        value;
        nonce;

        uint256 MaxSupply   = 21000000 ether;
        uint256 MintAmount  = 1000 ether; 
        uint256 HalveTimes  = 0;

        if (totalSupply >= MaxSupply){

            return 0;

        }
        
        while (totalSupply >= (MaxSupply - MaxSupply/(2**HalveTimes))){
            
            amount = MintAmount/(2**HalveTimes);
            HalveTimes += 1;

        }

        if (totalSupply + amount >= MaxSupply){

            amount = MaxSupply - totalSupply;
        
        }


    }

}
