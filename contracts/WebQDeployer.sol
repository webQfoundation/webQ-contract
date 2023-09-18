// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./nft/lib/SeaDropStructs.sol";

import "./nft/lib/ERC721SeaDropStructsErrorsAndEvents.sol";

import "./nft/openzeppelin-contracts/access/Ownable.sol";

import { Clones } from "./nft/openzeppelin-contracts/proxy/Clones.sol";

import "./WebQ.sol";

interface ISeaDrop {
    function mintSigned(
        address nftContract,
        address feeRecipient,
        address minterIfNotPayer,
        uint256 quantity,
        MintParams calldata mintParams,
        uint256 salt,
        bytes calldata signature
    ) external payable;
    function mintAllowedTokenHolder(
        address nftContract,
        address feeRecipient,
        address minterIfNotPayer,
        TokenGatedMintParams calldata mintParams
    ) external payable;
    function getAllowedNftTokenIdIsRedeemed(
        address nftContract,
        address allowedNftToken,
        uint256 allowedNftTokenId
    ) external view returns (bool);
}

interface IERC721SeaDropClonable is ERC721SeaDropStructsErrorsAndEvents{
    function setBaseURI(string calldata tokenURI) external;
    function setContractURI(string calldata newContractURI) external;
    function setMaxSupply(uint256 newMaxSupply) external;
    function updateSignedMintValidationParams(
        address seaDropImpl,
        address signer,
        SignedMintValidationParams memory signedMintValidationParams
    ) external;
    function updatePayer(address seaDropImpl, address payer, bool allowed) external;
    function updateAllowedFeeRecipient(address seaDropImpl, address feeRecipient, bool allowed) external;
    function updateTokenGatedDrop(address seaDropImpl, address allowedNftToken, TokenGatedDropStage calldata dropStage) external;
    function getMintStats(address minter)
        external
        view
        returns (
            uint256 minterNumMinted,
            uint256 currentTotalSupply,
            uint256 maxSupply
        );
    function transferOwnership(address newPotentialOwner) external;
    function multiConfigure(MultiConfigureStruct calldata config) external;
    function initialize(
        string calldata __name,
        string calldata __symbol,
        address[] calldata allowedSeaDrop,
        address initialOwner
    ) external;
}


contract WebQDeployer is Ownable, ERC721SeaDropStructsErrorsAndEvents {

    IERC721SeaDropClonable public NFT;

    IERC721SeaDropClonable public spNFT;

    ISeaDrop public seaDrop;

    address payable public webQBase;

    event WebQDeployed(address webQ, address fundReceiver, address NFT, address spNFT);

    constructor(address seaDropImplementation, 
                address payable fundReceiver,
                address nftSigner,
                address seaDropCloneableImplementation,
                string memory contractURIforNFT,
                string memory baseURIforNFT,
                string memory contractURIforspNFT,
                string memory baseURIforspNFT
                ){

        address[] memory allowedSeaDrop = new address [] (1);

        seaDrop = ISeaDrop(seaDropImplementation);

        webQBase= payable(new WebQ(fundReceiver));

        allowedSeaDrop[0] = seaDropImplementation;

        NFT = IERC721SeaDropClonable(Clones.clone(seaDropCloneableImplementation));

        NFT.initialize(
                'Web-Q NFT Badger',
                'Web-Q NFT',
                allowedSeaDrop,
                address(this)
            );

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
            seaDropImplementation,
            nftSigner,
            signValidationSetup
        );

        NFT.updatePayer(seaDropImplementation, address(this), true);
       
        NFT.updateAllowedFeeRecipient(seaDropImplementation, webQBase, true);

        spNFT = IERC721SeaDropClonable(Clones.clone(seaDropCloneableImplementation));

        spNFT.initialize(
            'Web-Q Special NFT Badger',
            'Web-Q spNFT',
            allowedSeaDrop,
            address(this)
        );

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
            seaDropImplementation,
            webQBase, 
            tokenGatedSetup
        );

        spNFT.setContractURI(contractURIforspNFT);

        spNFT.setBaseURI(baseURIforspNFT);

        spNFT.updatePayer(seaDropImplementation, address(this), true);

        spNFT.updateAllowedFeeRecipient(seaDropImplementation, webQBase, true);

        emit WebQDeployed(address(webQBase), address(fundReceiver), address(NFT), address(spNFT));

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
                webQBase, //feeRecipient
                msg.sender, //minter
                grantedNFT - _mintedNFT, //quantity
                _mintParams, //mintParams
                uint256(uint160(msg.sender)) + grantedNFT,  //salt
                signature
                );
        }

        if  (grantedSpNFTs.length > 0){
            seaDrop.mintAllowedTokenHolder(address(spNFT), webQBase, msg.sender, TokenGatedMintParams(webQBase, grantedSpNFTs));
        }
    }

    /**
     * @dev Donate to web-q.foundation and mint special NFTs within one transcation.
     *
     */
    function donationAndMint() external payable {
        uint256 oldMintable    = WebQ(webQBase).mintableSupply();
        
        (,uint256 newMintable) = WebQ(webQBase).donate{value: msg.value}(msg.sender);
        
        if (newMintable > oldMintable){
            uint256 [] memory grantedSpNFTs = new uint256[](newMintable - oldMintable);
            for (uint i = oldMintable; i < newMintable; i++){
                grantedSpNFTs[i-oldMintable] = i + 1;
            }

            seaDrop.mintAllowedTokenHolder(address(spNFT), webQBase, msg.sender, TokenGatedMintParams(webQBase, grantedSpNFTs));
        }
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
            if (WebQ(webQBase).ownerOf(grantedSpNFTs[i]) == minter && 
                !seaDrop.getAllowedNftTokenIdIsRedeemed(
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
     * @dev Transfer ownership of NFT contract in case of crtitial bugs.
     *
     * @param to to whom transfer ownership
     */
    function transferNftOwnership(address to)
        external
        onlyOwner{
            spNFT.transferOwnership(to);
            NFT.transferOwnership(to);
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
