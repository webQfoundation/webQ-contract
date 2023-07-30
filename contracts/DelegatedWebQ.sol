// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./safe/Safe.sol";
import "./qrc/QRC20/IQRC20.sol";


/**
 * @title DelegatedWebQ - Web Q contract using delegated gnosis safe to reduce deployment costs.
 * @author 0xTroll
 */
contract DelegatedWebQ is IQRC20 {

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
     * @dev Record donation to Web-Q.fundation.
     */
    event Donation(address donor, uint256 amount);

    /**
     * @dev Receive donation to Web-Q.fundation.
     */
    receive() external payable {
        if (msg.value > 0) {
            emit Donation(msg.sender, msg.value);
        }
    }

    /**
     * @dev Index will be stored at keccak256("QRC_INDEX_SLOT").
     */
    struct IndexSlot {
        uint256 value;
    }

    /**
     * @dev Implementation of  QRC entry interface.
     */

    function entryQRC(uint256 Q_address, bytes memory Q_message, bytes calldata Q_signature) payable external returns (bool){

        IndexSlot storage index;
        
        bytes32 index_slot= keccak256("QRC_INDEX_SLOT");

        assembly {
            index.slot := index_slot
        }

        if (msg.value > 0) {
            emit Donation(msg.sender, msg.value);
        }
        
        emit EntryQRC(index.value, Q_address, keccak256(Q_message), Q_signature);

        index.value = index.value + 1;

        return true;
    }


     /**
     * @dev Implementation of mintQRC
     */

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