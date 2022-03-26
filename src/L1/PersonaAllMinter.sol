pragma solidity ^0.8.10;

interface PersonaLike {
    function mint(address to) external;

    function personaMirrorL2() external view returns (address);
}

contract PersonaAllMinter {
    PersonaLike public personaContract;

    function setPersona(address personaContractAddress) public {
        personaContract = PersonaLike(personaContractAddress);
    }

    function mintPersona(address minterAddress) public {
        personaContract.mint(minterAddress);
    }
}
