// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./safe/Safe.sol";
import "./qrc/QRC20/QRC20.sol";

contract WebQ is Safe, QRC20 {
    /**
     * @dev Record donation to Web-Q.fundation.
     */
    event Donation(address donor, uint256 amount, uint256 totalDonation);

    uint256 public totalDonation;


    /**
     * @dev Special NFT badges will be rewarded to initial donors to Web-Q.Foundation,
     * @dev {ownerOf} function is for compatiblity with tokenGated ERC721 SeaDrop contract,
     * @dev in order to remeber donors eligible to receive special NFT badges.
     * @dev Only allowedMinter can mint the corresponding NFT.
     * @dev Note that the snapshot of total donation is used as unique marker.
     * @dev Note that the acutal NFT id is decided by the sequence of SeaDrop mingting. 
     */
    mapping (uint256=>address) public ownerOf;

    /**
     * @dev Grant {to} with pending special NFT, which can be accessed by ownerOf function.
     */
    function _grantSpecialNFT(address to, uint256 uniqueMarker) internal {

        ownerOf[uniqueMarker] = to;

    }


    function donate() payable public{
        if (msg.value > 0) {
            emit Donation(msg.sender, msg.value, totalDonation);
        }

        if (totalDonation < 55 ether && msg.value >= 1 ether){
        
            _grantSpecialNFT(msg.sender, totalDonation);
        
        } 

        else if (totalDonation < 205 ether && msg.value >= 5 ether){

            _grantSpecialNFT(msg.sender, totalDonation);

        }

        else if (msg.value >= 15 ether){
            
            _grantSpecialNFT(msg.sender, totalDonation);

        }

        totalDonation = totalDonation + msg.value;


    }

    function _afterQRC(bytes32 Q_address, bytes memory Q_message, bytes calldata Q_signature) override internal {
        Q_address;
        Q_message;
        Q_signature;
        if (msg.value> 0) {
            emit Donation(msg.sender, msg.value, totalDonation);
        }
    }

    function mintQRC(uint256 totalSupply, bytes32 Q_address, uint256 nonce, uint256 value) pure external override returns (uint256 amount){
        
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
