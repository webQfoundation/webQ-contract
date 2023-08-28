// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./safe/Safe.sol";
import "./safe/common/NativeCurrencyPaymentFallback.sol";
import "./qrc/QRC20/IQRC20.sol";


/**
 * @title DelegatedWebQ - Web Q contract using delegated gnosis safe to reduce deployment costs.
 * @author 0xTroll
 */
contract DelegatedWebQ is IQRC20, NativeCurrencyPaymentFallback {

    // According to gnosis safe protocol, 
    // Singleton always needs to be first declared variable, to ensure that it is at the same location in the contracts to which calls are delegated.
    address public safe;

    /**
     * @notice Constructor function sets address of singleton contract.
     * @param _singleton Singleton address.
     */
    constructor(address _singleton) {
        require(_singleton != address(0));
        safe = _singleton;
    }

    /// @dev Fallback function forwards all transactions and returns all received return data.
    fallback() external payable {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let _singleton := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            // 0xa619486e == keccak("masterCopy()"). The value is right padded to 32-bytes with 0s
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, _singleton)
                return(0, 0x20)
            }
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _singleton, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }

    /**
     * @dev Index will be stored at keccak256("QRC_INDEXSlot").
     * @dev Total Donation will be stored at keccak256("TOTAL_DONATION").
     */
    struct Uint256ValueSlot {
        uint256 value;
    }


    /**
     * @dev Record donation to Web-Q.fundation.
     */
    event Donation(address donor, uint256 amount, uint256 totalDonation);


    /**
     * @dev Access to total donation.
     */
    function totalDonation() external view returns (uint256 donation){

        bytes32 donationSlot= keccak256("TOTAL_DONATION");
    
        assembly {
            donation := sload(donationSlot)
        }

    }

    /**
     * @dev Special NFT badges will be rewarded to initial donors to Web-Q.Foundation,
     * @dev {ownerOf} function is for compatiblity with tokenGated ERC721 SeaDrop contract,
     * @dev in order to remeber donors eligible to receive special NFT badges.
     * @dev Only allowedMinter can mint the corresponding NFT.
     * @dev Note that the snapshot of total donation is used as unique marker.
     * @dev Note that the acutal NFT id is decided by the sequence of SeaDrop mingting. 
     */
    function ownerOf(uint256 uniqueMarker) external view returns (address allowedMinter){

        bytes32 nftSlot= keccak256(abi.encodePacked("PENDING_SPECIAL_NFT", uniqueMarker));
    
        assembly {
            allowedMinter := sload(nftSlot)
        }

    }

    /**
     * @dev Grant {to} with pending special NFT, which can be accessed by ownerOf function.
     */
    function _grantSpecialNFT(address to, uint256 uniqueMarker) internal {
        
        bytes32 nftSlot= keccak256(abi.encodePacked("PENDING_SPECIAL_NFT", uniqueMarker));

        assembly {
            sstore(nftSlot, to)
        }

    }


    function donate() payable public{
        Uint256ValueSlot storage donation;
        
        bytes32 donationSlot= keccak256("TOTAL_DONATION");

        assembly {
            donation.slot := donationSlot
        }

        if (msg.value > 0) {
            emit Donation(msg.sender, msg.value, donation.value);
        }

        if (donation.value < 55 ether && msg.value >= 1 ether){
        
            _grantSpecialNFT(msg.sender, donation.value);
        
        } 

        else if (donation.value < 205 ether && msg.value >= 5 ether){

            _grantSpecialNFT(msg.sender, donation.value);

        }

        else if (msg.value >= 15 ether){
            
            _grantSpecialNFT(msg.sender, donation.value);

        }

        donation.value = donation.value + msg.value;


    }

    /**
     * @dev Implementation of  QRC entry interface.
     */

    function entryQRC(bytes32 Q_address, bytes memory Q_message, bytes calldata Q_signature) payable external returns (bool){

        Uint256ValueSlot storage index;
        
        bytes32 indexSlot= keccak256("QRC_INDEXSlot");

        assembly {
            index.slot := indexSlot
        }

        donate();
        
        emit EntryQRC(index.value, Q_address, keccak256(Q_message), Q_signature);

        index.value = index.value + 1;

        return true;
    }


     /**
     * @dev Implementation of mintQRC
     */

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