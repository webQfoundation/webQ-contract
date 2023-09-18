// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

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
 * @title WebQ - Web Q contract with gnosis {safe} account as fund receiver.
 * @author 0xTroll
 */
contract WebQ is IQRC20 {

    // Foundation address is safe account.
    address payable public safe;

    /**
     * @notice Constructor function sets address of fund receiver contract.
     * @param _safe safe account address.
     */
    constructor(address payable _safe) {

        require(_safe != address(0));

        safe = _safe;

    }

    /**
     * @dev Total donation donated to Web-Q.fundation.
     */
    uint256 public totalDonation;


    /**
     * @notice Current index for QRC transactions.
     */
    uint256 public qrcIndex;


    /**
     * @dev Current mintable specical NFT supply.
     */
    uint256 public mintableSupply;


    /**
     * @dev Allowner minter for given mintId.
     */
    mapping (uint256=>address) internal allowedMinterForMintId;

    /**
     * @dev Total donation donated to Web-Q.fundation.
     */
    event Donation(address donor, uint256 amount, uint256 totalDonation);

    /**
     * @dev Grant spNFT for donors who make considerable contribution.
     */
    event GrantSpNFT(address donor, uint256 mintId);


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
        donationRequired = donationForSpNfts(deltaAmount, mintableSupply);
    }

    /**
     * @dev Special NFT badges will be rewarded to initial donors to Web-Q.Foundation,
     * @dev {ownerOf} function is for compatiblity with tokenGated ERC721 SeaDrop contract,
     * @dev in order to remeber donors eligible to receive special NFT badges.
     * @dev Only allowedMinter can mint the corresponding NFT.
     * @dev Note that the snapshot of total donation is used as unique marker.
     * @dev Note that the acutal NFT id is decided by the sequence of SeaDrop mingting. 
     */
    function ownerOf(uint256 mintId) external view returns (address allowedMinter){

        allowedMinter = allowedMinterForMintId[mintId];

    }

    /**
     * @dev Grant {to} with pending special NFT, which can be accessed by ownerOf function with {uniqueMarker} as minting id.
     */
    function _grantSpecialNFT(address to, uint256 mintId) internal {

        require( to != address(0) );
        
        allowedMinterForMintId[mintId] = to;

        emit GrantSpNFT(to, mintId);

    }

    /**
     * @dev Handle donation, trying to grant special NFTs.
     * @dev visit https://web-q.foundation for more information.
     */
    function donate(address donor) payable public returns (uint256 donation, uint256 mintable){
        
        //storage -> memory
        mintable = mintableSupply;

        uint256 _value = msg.value;
        uint256 _threshold;

        if (_value > 0) {
            emit Donation(donor, _value, totalDonation);
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
        
        totalDonation += msg.value;

        donation = totalDonation;

        //memory -> storage 
        mintableSupply = mintable;

        (bool success, ) = safe.call{value: msg.value}("");
        
        require(success);
    }

    /**
     * @dev Implementation of  QRC entry interface.
     * @dev visit https://web-q.foundation for more information.
     * Note that donation is triggered to handle donation.
     */

    function entryQRC(bytes32 Q_address, bytes memory Q_message, bytes calldata Q_signature) payable external returns (bool){

        donate(msg.sender);
        
        emit EntryQRC(qrcIndex, Q_address, keccak256(Q_message), Q_signature);

        qrcIndex += 1;

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

     /**
     * @dev Fund received will be transfered to {safe} account by default.
     */

    receive() external payable {
        safe.transfer(msg.value);
    }

}
