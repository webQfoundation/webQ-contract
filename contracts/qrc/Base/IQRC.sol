// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Interface of the QRC Protocol.
 */
interface IQRC {
    /**
     * @dev Emitted when receciving QRC Transaction.
     *
     * Note that `Q_signature` must be checked off-line.
     */
    event EntryQRC(uint256 Q_address, bytes32 Q_message_hash, bytes Q_signature);


    /**
     * @dev invoke an QRC transaction from `Q_address`, with message `Q_message` and signature `Q_signature`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {EntryQRC} event.
     */
    function entryQRC(uint256 Q_address, bytes memory Q_message, bytes calldata Q_signature) external returns (bool);
}