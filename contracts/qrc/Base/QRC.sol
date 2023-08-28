// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import {IQRC} from "./IQRC.sol";

/**
 * @title QRC Base - An implementation of QRC protocol basical standards.
 * @author 0xTroll
 */
abstract contract QRC is IQRC {

    /**
     * @dev index of QRC transations.
     */

    uint256 public index = 0;

    /**
     * @dev entry for QRC transation.
     */

    function entryQRC(bytes32 Q_address, bytes memory Q_message, bytes calldata Q_signature) payable external returns (bool){

        _beforeQRC(Q_address, Q_message, Q_signature);
        
        emit EntryQRC(index, Q_address, keccak256(Q_message), Q_signature);

        index += 1;

        _afterQRC(Q_address, Q_message, Q_signature);

        return true;
    }

    /**
     * @dev Hook that is called before QRC handler. This may include handling authority check like Q_address blacklist/whitelist.
     */
    function _beforeQRC(bytes32 Q_address, bytes memory Q_message, bytes calldata Q_signature) internal virtual {}

    /**
     * @dev Hook that is called after QRC handler. This may include registering or storing QRC transaction.
     */
    function _afterQRC(bytes32 Q_address, bytes memory Q_message, bytes calldata Q_signature) internal virtual {}
}
