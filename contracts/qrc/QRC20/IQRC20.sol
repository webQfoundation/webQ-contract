// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.7.0 <0.9.0;

import {IQRC} from "../Base/IQRC.sol";

/**
 * @dev Interface of the QRC20 Protocol.
 */
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