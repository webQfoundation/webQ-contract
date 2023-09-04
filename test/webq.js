const Safe = artifacts.require("Safe");
const DelegatedWebQ = artifacts.require("DelegatedWebQ");
const WebQ = artifacts.require("WebQ");
const SeaDrop = artifacts.require("SeaDrop");
const ERC721SeaDrop = artifacts.require("ERC721SeaDrop");

contract('WebQ and NFTs', async (accounts) => {
    const webq = await WebQ.at(DelegatedWebQ.address);
    const dwebq = await DelegatedWebQ.deployed();
    const nft = await ERC721SeaDrop.new('Web-Q NFT Badger', 'Web-Q NFT Badger', [SeaDrop.address]);
    await nft.updateTokenGatedDrop(SeaDrop.address, DelegatedWebQ.address, 
        [   0    ,//uint80 mintPrice; // 80/256 bits
            108    ,//uint16 maxTotalMintableByWallet; // 96/256 bits
            0   ,//uint48 startTime; // 144/256 bits
            '281474976710655'    ,//uint48 endTime; // 192/256 bits
            0    ,//uint8 dropStageIndex; // non-zero. 200/256 bits
            108    ,//uint32 maxTokenSupplyForStage; // 232/256 bits
            0    ,//uint16 feeBps; // 248/256 bits
            false    //bool restrictFeeRecipients
        ]);
    it('should grant sp nft when donated', async () =>{
       await dwebq.donate({from: accounts[0], value: '1000000000000000000'});
       let m = await dwebq.totalDonation.call();
       assert.equal(await dwebq.ownerOf.call(m), accounts[0]);
    });
    it('should mint sp nft', async () =>{
      let seadrop = await SeaDrop.deployed();
      await seadrop.mintAllowedTokenHolder(nft.address, address[0], [DelegatedWebQ.address, [m]]);
      assert.equal(await nft.balanceOf.call(address[0]), 1);
   });
   it('should set safe contract', async () =>{
    //await webq.setup;
 });
   it('should handle ownership to safe', async () =>{
    let seadrop = await SeaDrop.deployed();
    await seadrop.mintAllowedTokenHolder(nft.address, address[0], [DelegatedWebQ.address, [m]]);
    assert.equal(await nft.balanceOf.call(address[0]), 1);
 });
})

