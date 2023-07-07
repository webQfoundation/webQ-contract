// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import {IQRC} from "./IQRC.sol";

/**
 * @title QRC Base - An implementation of QRC protocol basical standards.
 * @author 0xTroll
 */
abstract contract QRC is IQRC {

    /**
     * @dev entry for QRC transation.
     */

    function entryQRC(uint256 Q_address, bytes memory Q_message, bytes calldata Q_signature) external returns (bool){

        _beforeQRC(Q_address, Q_message, Q_signature);
        
        emit EntryQRC(Q_address, keccak256(Q_message), Q_signature);

        _afterQRC(Q_address, Q_message, Q_signature);

        return true;
    }

    /**
     * @dev Hook that is called before QRC handler. This may include handling authority check like Q_address blacklist/whitelist.
     */
    function _beforeQRC(uint256 Q_address, bytes memory Q_message, bytes calldata Q_signature) internal virtual {}

    /**
     * @dev Hook that is called after QRC handler. This may include registering or storing QRC transaction.
     */
    function _afterQRC(uint256 Q_address, bytes memory Q_message, bytes calldata Q_signature) internal virtual {}
}