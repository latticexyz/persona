pragma solidity ^0.8.10;

interface Persona {
    function mint(address to) external;
}

contract PersonaAllMinter {
    Persona public personaContract;

    constructor(address personaContractAddress) {
        personaContract = Persona(personaContractAddress);
    }

    function mintPersona(address minterAddress) public {
        personaContract.mint(minterAddress);
    }
}
