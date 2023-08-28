// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./nft/ERC721SeaDrop.sol";

import "./nft/SeaDrop.sol";

import "./nft/lib/SeaDropStructs.sol";

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

contract WebQNFTHub {

    ERC721SeaDropLegacyOwnable public NFT;

    ERC721SeaDropLegacyOwnable public spNFT;

    SeaDrop internal seaDrop;

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
       
        NFT.transferOwnership(webQBase);

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

        spNFT.transferOwnership(webQBase);

        _DOMAIN_SEPARATOR = _deriveDomainSeparator();

    }


    /**
     * @dev Internal view for NFT mintParams.
     */
    MintParams internal _mintParams = MintParams(
        0,1,0,type(uint256).max,1,10000,0,false
    );


    /**
     * @dev Check if salt is used for NFT minting.
     */
    mapping (uint256 => bool) public saltUsed;


    /**
     * @dev Record routed minting history.
     */
    event RoutedMint(address from, uint256 salt, uint256 spGrant);


    /**
     * @dev Mint NFTs and special NFTs in one function.
     */
    function batchMintNFT(uint256[] calldata salts, bytes[] calldata signatures, uint256[] calldata spGrants) external {
        
        for (uint i=0; i<salts.length; i++){
            
            if (!saltUsed[salts[i]]){
                
                seaDrop.mintSigned(address(NFT), msg.sender, msg.sender, 1, _mintParams, salts[i], signatures[i]);
                
                saltUsed[salts[i]] = true;

                emit RoutedMint(msg.sender, salts[i], type(uint256).max);

            }

        }

        seaDrop.mintAllowedTokenHolder(address(spNFT), msg.sender, msg.sender, TokenGatedMintParams(webQBase, spGrants));

        for (uint i=0; i<spGrants.length; i++) emit RoutedMint(msg.sender, type(uint256).max, spGrants[i]);

    }

    /// @notice Internal constants for EIP-712: Typed structured
    ///         data hashing and signing
    bytes32 internal constant _SIGNED_MINT_TYPEHASH =
        // prettier-ignore
        keccak256(
             "SignedMint("
                "address nftContract,"
                "address minter,"
                "address feeRecipient,"
                "MintParams mintParams,"
                "uint256 salt"
            ")"
            "MintParams("
                "uint256 mintPrice,"
                "uint256 maxTotalMintableByWallet,"
                "uint256 startTime,"
                "uint256 endTime,"
                "uint256 dropStageIndex,"
                "uint256 maxTokenSupplyForStage,"
                "uint256 feeBps,"
                "bool restrictFeeRecipients"
            ")"
        );
    bytes32 internal constant _MINT_PARAMS_TYPEHASH =
        // prettier-ignore
        keccak256(
            "MintParams("
                "uint256 mintPrice,"
                "uint256 maxTotalMintableByWallet,"
                "uint256 startTime,"
                "uint256 endTime,"
                "uint256 dropStageIndex,"
                "uint256 maxTokenSupplyForStage,"
                "uint256 feeBps,"
                "bool restrictFeeRecipients"
            ")"
        );
    bytes32 internal constant _EIP_712_DOMAIN_TYPEHASH =
        // prettier-ignore
        keccak256(
            "EIP712Domain("
                "string name,"
                "string version,"
                "uint256 chainId,"
                "address verifyingContract"
            ")"
        );
    bytes32 internal constant _NAME_HASH = keccak256("SeaDrop");
    bytes32 internal constant _VERSION_HASH = keccak256("1.0");
    uint256 internal immutable _CHAIN_ID = block.chainid;
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    /**
     * @dev Internal view function to get the EIP-712 domain separator. If the
     *      chainId matches the chainId set on deployment, the cached domain
     *      separator will be returned; otherwise, it will be derived from
     *      scratch.
     *
     * @return The domain separator.
     */
    function _domainSeparator() internal view returns (bytes32) {
        // prettier-ignore
        return block.chainid == _CHAIN_ID
            ? _DOMAIN_SEPARATOR
            : _deriveDomainSeparator();
    }

    /**
     * @dev Internal view function to derive the EIP-712 domain separator.
     *
     * @return The derived domain separator.
     */
    function _deriveDomainSeparator() internal view returns (bytes32) {
        // prettier-ignore
        return keccak256(
            abi.encode(
                _EIP_712_DOMAIN_TYPEHASH,
                _NAME_HASH,
                _VERSION_HASH,
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @notice Verify an EIP-712 signature by recreating the data structure
     *         that we signed on the client side, and then using that to recover
     *         the address that signed the signature for this data.
     *
     * @param nftContract  The nft contract.
     * @param minter       The mint recipient.
     * @param feeRecipient The fee recipient.
     * @param mintParams   The mint params.
     * @param salt         The salt for the signed mint.
     */
    function _getDigest(
        address nftContract,
        address minter,
        address feeRecipient,
        MintParams memory mintParams,
        uint256 salt
    ) internal view returns (bytes32 digest) {
        bytes32 mintParamsHashStruct = keccak256(
            abi.encode(
                _MINT_PARAMS_TYPEHASH,
                mintParams.mintPrice,
                mintParams.maxTotalMintableByWallet,
                mintParams.startTime,
                mintParams.endTime,
                mintParams.dropStageIndex,
                mintParams.maxTokenSupplyForStage,
                mintParams.feeBps,
                mintParams.restrictFeeRecipients
            )
        );
        digest = keccak256(
            bytes.concat(
                bytes2(0x1901),
                _domainSeparator(),
                keccak256(
                    abi.encode(
                        _SIGNED_MINT_TYPEHASH,
                        nftContract,
                        minter,
                        feeRecipient,
                        mintParamsHashStruct,
                        salt
                    )
                )
            )
        );
    }


    /*
     * @notice prepare data for server to sign.
     *
     * @return digest  The corresponding bytes32 data to sign.
     */
    function getMintDigested(address minter, uint256 salt) external view returns(bytes32 digest){
        
        digest = _getDigest(address(NFT), minter, minter, _mintParams, salt);

    }

    
}
