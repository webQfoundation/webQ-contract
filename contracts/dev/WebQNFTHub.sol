// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../nft/ERC721SeaDrop.sol";

import "../nft/SeaDrop.sol";

import "../nft/lib/SeaDropStructs.sol";

import "../nft/lib/ERC721SeaDropStructsErrorsAndEvents.sol";

import "../nft/openzeppelin-contracts/access/Ownable.sol";

contract ERC721SeaDropLegacyOwnable is ERC721SeaDrop {

    constructor(
        string memory name,
        string memory symbol,
        address[] memory allowedSeaDrop
    )ERC721SeaDrop(name, symbol, allowedSeaDrop) {}

    function transferOwnership(address newPotentialOwner)
        public
        override
        onlyOwner
    {
        if (newPotentialOwner == address(0)) {
            revert NewOwnerIsZeroAddress();
        }
        _transferOwnership(newPotentialOwner);
    }

}

contract WebQNFTHub is Ownable, ERC721SeaDropStructsErrorsAndEvents {

    ERC721SeaDropLegacyOwnable public NFT;

    ERC721SeaDropLegacyOwnable public spNFT;

    SeaDrop public seaDrop;

    address internal webQBase;


    constructor(address seaDrop_, 
                address webQBase_,
                address signer,
                string memory contractURIforNFT,
                string memory baseURIforNFT,
                string memory contractURIforspNFT,
                string memory baseURIforspNFT
                ){

        address[] memory allowedSeaDrop = new address [] (1);

        seaDrop = SeaDrop(seaDrop_);

        webQBase= webQBase_;

        allowedSeaDrop[0] = seaDrop_;

        NFT = new ERC721SeaDropLegacyOwnable('WebQ NFT Badger', 'WebQ NFT', allowedSeaDrop);

        SignedMintValidationParams memory signValidationSetup = SignedMintValidationParams(
            0    ,//uint80 minMintPrice; 
            10000    ,//uint24 maxMaxTotalMintableByWallet; 
            0    ,//uint40 minStartTime; 
            uint40(type(uint40).max)    ,//uint40 maxEndTime; 
            10000    ,//uint40 maxMaxTokenSupplyForStage; 
            0    ,//uint16 minFeeBps; 
            0     //uint16 maxFeeBps; 
        );

        NFT.setContractURI(contractURIforNFT);

        NFT.setBaseURI(baseURIforNFT);

        NFT.setMaxSupply(10000);

        NFT.updateSignedMintValidationParams(
            seaDrop_,
            signer,
            signValidationSetup
        );

        NFT.updatePayer(seaDrop_, address(this), true);
       
        NFT.updateAllowedFeeRecipient(seaDrop_, webQBase, true);

        spNFT = new ERC721SeaDropLegacyOwnable('WebQ Special NFT Badger', 'WebQ spNFT', allowedSeaDrop);

        TokenGatedDropStage memory tokenGatedSetup = TokenGatedDropStage(
            0    ,//uint80 mintPrice; 
            108    ,//uint16 maxTotalMintableByWallet; 
            0   ,//uint48 startTime; 
            uint48(type(uint48).max),//uint48 endTime; 
            1    ,//uint8 dropStageIndex; // non-zero. 
            108    ,//uint32 maxTokenSupplyForStage; 
            0    ,//uint16 feeBps; 
            false    //bool restrictFeeRecipients
        );

        spNFT.setMaxSupply(108);

        spNFT.updateTokenGatedDrop(
            seaDrop_,
            webQBase, 
            tokenGatedSetup
        );

        spNFT.setContractURI(contractURIforspNFT);

        spNFT.setBaseURI(baseURIforspNFT);

        spNFT.updatePayer(seaDrop_, address(this), true);

        spNFT.updateAllowedFeeRecipient(seaDrop_, webQBase, true);


    }

    
    /**
     * @dev Check if salt is used for NFT minting.
     */
    mapping (uint256 => bool) public saltUsed;


    /**
     * @dev Record routed minting history.
     */
    event MintNFT(address from, address nftContract, uint256 spGrant);


    /**
     * @dev Mint NFTs and special NFTs in one function.
     *
     * @param grantedNFT last index of NFT to be minted.
     * @param signature server-side signature to mint NFT.
     * @param grantedSpNFTs ids of spNFT to be minted (not the final NFT id). Should be checked using claimableSpNFT.
     */
    function mintNFT(uint256 grantedNFT, bytes calldata signature, uint256[] calldata grantedSpNFTs) external {
        
        (uint256 _mintedNFT,,) = NFT.getMintStats(msg.sender); 

        if (grantedNFT > _mintedNFT){
            MintParams memory _mintParams = MintParams(
                0,grantedNFT,0,4070880000,1,10000,0,true
            );
            seaDrop.mintSigned(
                address(NFT), //nftContract
                msg.sender, //minter
                webQBase, //feeRecipient
                grantedNFT - _mintedNFT, //quantity
                _mintParams, //mintParams
                uint256(uint160(msg.sender)) + grantedNFT,  //salt
                signature
                );
        }

        seaDrop.mintAllowedTokenHolder(address(spNFT), msg.sender, webQBase, TokenGatedMintParams(webQBase, grantedSpNFTs));
    }

    /**
     * @dev Check how many NFTs that have been minted by minter.
     *
     * @param minter whoever wants to mint spNFT.
     *
     * @return minted quantity of NFTs minted by minter.
     */
    function mintedNFT(address minter) external view returns(uint256 minted){
        (minted,,) = NFT.getMintStats(minter); 
    }

    /**
     * @dev Mint NFTs and special NFTs in one function.
     *
     * @param minter whoever wants to mint spNFT.
     * @param grantedSpNFTs ids of spNFT to be checked.
     *
     * @return mintableSpNFTs ids of spNFT can be minted (not the final NFT id).
     */
    function claimableSpNFT(address minter, uint256[] calldata grantedSpNFTs) external view returns(uint256[] memory mintableSpNFTs){
        uint256[] memory mintableSpNFTsPadded = new uint256[](grantedSpNFTs.length);
        uint256 mintableSpNFTsLength = 0;
        for (uint i=0; i<grantedSpNFTs.length; i++) {
            if (spNFT.ownerOf(grantedSpNFTs[i]) == minter && 
                seaDrop.getAllowedNftTokenIdIsRedeemed(
                    address(spNFT), webQBase, grantedSpNFTs[i]
                    )){
                        mintableSpNFTsPadded[mintableSpNFTsLength] = grantedSpNFTs[i];
                        mintableSpNFTsLength += 1;
                    }
        }
        mintableSpNFTs = new uint256[](mintableSpNFTsLength);
        for (uint i=0; i<mintableSpNFTsLength; i++){
            mintableSpNFTs[i] = mintableSpNFTsPadded[i];
        }
    }
    

    /**
     * @dev Configure multiple properties at a time.
     *
     * @param isSpNFT true: config spNFT, false: config NFT.
     * @param config The configuration struct.
     */
    function multiConfigure(bool isSpNFT,MultiConfigureStruct calldata config)
        external
        onlyOwner{
            if (isSpNFT){
                spNFT.multiConfigure(config);
            } else {
                NFT.multiConfigure(config);
            }
        }
    
}
