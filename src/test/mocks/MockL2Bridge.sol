// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract MockL2Bridge {
    address sender;

    function xDomainMessageSender() external view returns (address) {
        return sender;
    }

    function sendMessage(
        address target,
        bytes memory message,
        uint32 gasLimit
    ) public {
        sender = msg.sender;
        (bool success, ) = target.call{gas: gasLimit}(message);
        sender = address(0);
        require(success);
    }
}
