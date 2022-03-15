pragma solidity ^0.8.10;

interface PersonaLike {
    function mint(address to) external;
}

contract PersonaAllMinter {
    PersonaLike public personaContract;

    constructor(address personaContractAddress) {
        personaContract = PersonaLike(personaContractAddress);
    }

    function mintPersona(address minterAddress) public {
        personaContract.mint(minterAddress);
    }
}
