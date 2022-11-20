// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./YokaiMinterGateway.sol";


contract YokaiCore is ERC721Enumerable, YokaiMinterGateway {

    constructor(address minterGateway) YokaiMinterGateway(minterGateway) ERC721("Yokai","YOKAI") {
        speciesLeft[1]=100;
        speciesLeft[2]=100;
        speciesLeft[3]=20;
        speciesLeft[4]=50;
        speciesLeft[5]=50;
        speciesLeft[6]=50;
        speciesLeft[7]=5;
        speciesLeft[8]=5;
    }

    struct Yokai {
        uint256 species;
        uint8[6] statistics;
        uint8[3] phattack;
        uint8[3] mgcattack;
    }

    //Store our nft
    Yokai[] public yokai;
    //Takes track of remaining species
    mapping(uint256 => uint256) private speciesLeft;
    mapping(uint256 => uint256) private speciesMinted;
    mapping(address => mapping(uint256 => bool)) private seenNonces;
    mapping(address => uint256) private lastSeenNonce;
    mapping(address => uint256) private tickets;
    mapping(address => mapping(uint256 => bool)) private addressToSummonTicket;

    function addSpecie(uint256 _specie, uint256 _amount) public {
        require(speciesLeft[_specie]==0);
        speciesLeft[_specie]=_amount;
    }

    function getTicket(address _address) public view returns(uint256) {
        return(tickets[_address]);
    }

    function buyTicket() public {
        require(canBuyTicket(msg.sender));
        tickets[msg.sender] = tickets[msg.sender] + 1;
    }

    function canBuyTicket(address buyer) public view returns(bool){
        return(lastSeenNonce[buyer]==tickets[buyer]);
    }

    function hasTicket(address _from) public view returns(bool) {
        return(tickets[_from]>lastSeenNonce[_from]);
    }

    function testMint(uint256 species, uint8[3] memory _phattack, uint8[3] memory _mgcattack) public {
        uint8[6] memory stats = [1,1,1,1,1,1];

        Yokai memory minted = Yokai(species, stats, _phattack, _mgcattack);
        yokai.push(minted);
        uint id = yokai.length-1;
        _mint( msg.sender, id ); 
    }

    function checkSeenNonce(uint256 _nonce) public view returns(bool) {
        return (seenNonces[msg.sender][_nonce]);
    }

    function mint(uint _token,uint8[3] memory _phattack, uint8[3] memory _mgcattack, uint _nonce, bytes memory _signature) public {
        //Controlla che la firma sia valida
        require(verify(gatewayAddress, msg.sender, _token, _phattack, _mgcattack, "Minting yokai", _nonce, _signature),"Not valid signature");
        //Controlla che il nonce non sia gia stato utilizzato
        require(!checkSeenNonce(_nonce));
        //Controlla che le specie rimanenti siano maggiori di 0
        require(speciesLeft[_token]>0, "Not enough species");
        //Aggiungi il nonce ai visualizzati
        seenNonces[msg.sender][_nonce] = true;
        //Aggiungi il nonce all'ultimo visualizzato
        lastSeenNonce[msg.sender] = _nonce;
        //Decrementa le specie rimanenti
        speciesLeft[_token] = speciesLeft[_token] - 1;
        //Aumenta le specie mintate
        speciesMinted[_token] = speciesMinted[_token] + 1;
        //Genera le statistiche
        uint8[6] memory stats = [1,1,1,1,1,1];
        Yokai memory minted = Yokai(_token, stats, _phattack, _mgcattack);
        yokai.push(minted);
        uint id = yokai.length-1;
        _mint(msg.sender, id);
    }

    function getSpeciesMinted(uint256 _token) public view returns(uint256) {
        return speciesMinted[_token];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 species = getSpecies(tokenId);
        return super.tokenURI(species);
    }

    function getYokai (uint256 _tokenId) public view returns(Yokai memory) {
        return yokai[_tokenId];
    }

    function getYokaiStatistics (uint256 _tokenId) public view returns(uint8[6] memory) {
        return yokai[_tokenId].statistics;
    }

    function getSpecies ( uint256 _tokenId ) public view returns(uint256) {
        return yokai[_tokenId].species;
    }

    function getRemainingSpeciesByTokenId ( uint256 _tokenId ) public view returns (uint256) {
        uint _species = getSpecies(_tokenId);
        return speciesLeft[_species];
    }

    function getRemainingSpegiesBySpeciesId ( uint256 _species ) public view returns (uint256) {
        return speciesLeft[_species];
    }

}
