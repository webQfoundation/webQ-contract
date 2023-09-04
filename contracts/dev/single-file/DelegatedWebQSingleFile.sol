// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title NativeCurrencyPaymentFallback - A contract that has a fallback to accept native currency payments.
 * @author Richard Meissner - @rmeissner
 */
abstract contract NativeCurrencyPaymentFallback {
    event SafeReceived(address indexed sender, uint256 value);

    /**
     * @notice Receive function accepts native currency transactions.
     * @dev Emits an event with sender and received value.
     */
    receive() external payable virtual {
        emit SafeReceived(msg.sender, msg.value);
    }
}


/**
 * @dev Interface of the QRC Protocol.
 */
interface IQRC {
    /**
     * @dev Emitted when receciving QRC Transaction.
     *
     * Note that `Q_signature` must be checked off-line.
     */
    event EntryQRC(uint256 indexed index, bytes32 indexed Q_address, bytes32 Q_message_hash, bytes Q_signature);


    /**
     * @dev invoke an QRC transaction from `Q_address`, with message `Q_message` and signature `Q_signature`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {EntryQRC} event.
     */
    function entryQRC(bytes32 Q_address, bytes memory Q_message, bytes calldata Q_signature) payable external returns (bool);
}

interface IQRC20 is IQRC {
    /**
     * @dev calculate QRC minting amount.
     *
     * @param totalSupply current total supply of QRC20, given by calcultion from previous QRC txs.
     * @param Q_address bytes32 Q_address that sends the QRC tx.
     * @param nonce uint256 current nonce for the Q_address. (nonce for QRC tx instead of wrapped tx.)
     * @param value uint256 carried value of the corresponding wrapped tx. 
     *
     * @return amount uint256 value indicating the amount of minted token.
     *
     * THIS FUNCTION SHALL BE STATIC.
     */
    function mintQRC(uint256 totalSupply, bytes32 Q_address, uint256 nonce, uint256 value) view external returns (uint256 amount);
}


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

    /**
     * @notice Since we are using delegated Gnosis Safe Protocol, specific low-level storage slots shall be used for information storage.
     */

    bytes32 private constant DonationSlot = keccak256("web-q.foundation.donation");

    bytes32 private constant QRCIndexSlot = keccak256("web-q.foundation.index");

    bytes32 private constant SpNFTSlotPrf = keccak256("web-q.foundation.spnft.allowedMinter");

    bytes32 private constant MintableSlot = keccak256("web-q.foundation.spnft.mintable");


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
     * @dev Total donation donated to Web-Q.fundation.
     */
    event Donation(address donor, uint256 amount, uint256 totalDonation);

    /**
     * @dev Grant spNFT for donors who make considerable contribution.
     */
    event GrantSpNFT(address donor, uint256 mintId);


    /**
     * @dev Access to total donation.
     */
    function totalDonation() external view returns (uint256 donation){
        bytes32 _donationSlot = DonationSlot;

        assembly {
            donation := sload(_donationSlot)
        }

    }

    /**
     * @dev How many spNft can be minted.
     */
    function mintableSupply() external view returns (uint256 mintable){
        bytes32 _mintableSlot = MintableSlot;

        assembly {
            mintable := sload(_mintableSlot) 
        }
    }

    /**
     * @dev Calculate how much donation required to mint {deltaAmount} spNFT when current supply is {supplyAmount} .
     */
    function donationForSpNfts(uint256 deltaAmount, uint256 supplyAmount) internal pure returns (uint256 donationRequired){

        uint256 nextAmount = deltaAmount + supplyAmount;

        
        donationRequired = ((nextAmount**2 - supplyAmount **2) * 25  + (nextAmount - supplyAmount) * 975) * 1e15;

    }

    /**
     * @dev Calculate how much donation required to mint {deltaAmount} spNFT .
     */
    function donationForSpNfts(uint256 deltaAmount) external view returns (uint256 donationRequired){
        uint256 mintable;

        bytes32 _mintableSlot = MintableSlot;

        assembly {
            mintable := sload(_mintableSlot) 
        }

        donationRequired = donationForSpNfts(deltaAmount, mintable);
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

        bytes32 _nftSlot= keccak256(abi.encodePacked(SpNFTSlotPrf, uniqueMarker));
    
        assembly {
            allowedMinter := sload(_nftSlot)
        }

    }

    /**
     * @dev Grant {to} with pending special NFT, which can be accessed by ownerOf function with {uniqueMarker} as minting id.
     */
    function _grantSpecialNFT(address to, uint256 uniqueMarker) internal {
        
        bytes32 _nftSlot= keccak256(abi.encodePacked(SpNFTSlotPrf, uniqueMarker));

        assembly {
            sstore(_nftSlot, to)
        }

        emit GrantSpNFT(to, uniqueMarker);
    }

    /**
     * @dev Handle donation, trying to grant special NFTs.
     * @dev visit https://web-q.foundation for more information.
     */
    function donate(address donor) payable public returns (uint256 donation, uint256 mintable){
        bytes32 _donationSlot = DonationSlot;
        bytes32 _mintableSlot = MintableSlot;

        assembly {
            donation := sload(_donationSlot)
            mintable := sload(_mintableSlot) 
        }

        uint256 _value = msg.value;
        uint256 _threshold;

        if (_value > 0) {
            emit Donation(donor, _value, donation);
        }

        while (mintable < 108) {
            _threshold = donationForSpNfts(1, mintable);
            if (_value >= _threshold){
                _value -= _threshold;
                mintable += 1;
                _grantSpecialNFT(donor, mintable);
            } else{
                break;
            }
        }
        
        donation += msg.value;

        assembly {
            sstore(_donationSlot, donation)
            sstore(_mintableSlot, mintable)
        }
    }

    /**
     * @dev Implementation of  QRC entry interface.
     * @dev visit https://web-q.foundation for more information.
     * Note that donation is triggered to handle donation.
     */

    function entryQRC(bytes32 Q_address, bytes memory Q_message, bytes calldata Q_signature) payable external returns (bool){

        uint256 index;
        
        bytes32 indexSlot = QRCIndexSlot;

        assembly {
            index := sload(indexSlot)
        }

        donate(msg.sender);
        
        emit EntryQRC(index, Q_address, keccak256(Q_message), Q_signature);

        index += 1;

        assembly {
            sstore(indexSlot, index)
        }

        return true;
    }


     /**
     * @dev Implementation of mintQRC, according to QRC-20 protocol.
     * @dev visit https://web-q.foundation for more information.
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