//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import { DefaultOperatorFilterer } from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import { ERC721MPF } from "./ERC721MPF.sol";
import { ILaunchpad } from "./ILaunchpad.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
contract MintPassFactory is Ownable, ERC721MPF
{
    struct MintPass
    {
        uint _MaxSupply;          // _MaxSupply
        uint _MintPacks;          // _MintPacks
        uint _ArtistIDs;          // _ArtistIDs
        uint _ArtBlocksProjectID; // _ArtBlocksProjectID note: For Cases Where Mint Pass ProjectID 1:1 With ProjectIDs
        uint _ReserveAmount;      // _Reserve
        string _MetadataURI;      // _MetadataURI
    }

    uint public _TotalUniqueProjects;  // Total Projects Invoked
    address public _Multisig; // test
    uint private constant _ONE_MILLY = 1_000_000; // one million boi
    uint private constant _DEFAULT = type(uint).max; // max integer

    mapping(uint=>MintPass) public MintPasses;
    mapping(uint=>uint) public ArtistIDs;
    mapping(address=>bool) public Authorized;
    mapping(uint=>uint[]) public MintPackIndexes;
    
    event MintPassProjectCreated(uint MintPassProjectID);
    event AuthorizedContract(address ContractAddress);
    event DeauthorizedContract(address ContractAddress);

    /**
     * @dev Mint Pass Factory Constructor
     */
    constructor() ERC721MPF("Bright Moments Mint Pass Factory | MPBRT", "MPBRT") 
    { 
        Authorized[msg.sender] = true; 
        _Multisig = msg.sender;
    }

    /**
     * @dev Returns All Mint Pack Indexes
     */
    function ReadMintPackIndexes(uint MintPassProjectID) public view returns (uint[] memory) { return MintPackIndexes[MintPassProjectID]; }

    /**
     * @dev MintPassFactory
     */
    function purchaseTo(address Recipient, uint ProjectID) external payable returns (uint NextTokenID)
    {
        NextTokenID = ReadNextTokenID(ProjectID);
        _mint(ProjectID, Recipient, 1);
        return NextTokenID;
    }

    /**
     * @dev Direct Mint Function
     */
    function _MintToFactory(uint MintPassProjectID, address Recipient, uint Amount) external onlyAuthorized
    {
        require(_Active[MintPassProjectID], "MintPassFactory: ProjectID: `MintPassProjectID` Is Not Active");
        _mint(MintPassProjectID, Recipient, Amount);
    }

    /**
     * @dev Direct Mint To Factory Pack
     */
    function _MintToFactoryPack(uint MintPassProjectID, address Recipient, uint Amount) external onlyAuthorized
    {
        require(_Active[MintPassProjectID], "MintPassFactory: ProjectID: `MintPassProjectID` Is Not Active");
        uint NumArtists = MintPasses[MintPassProjectID]._ArtistIDs;
        uint NumToMint = NumArtists * Amount;
        uint StartingTokenID = ReadProjectInvocations(MintPassProjectID);
        _mint(MintPassProjectID, Recipient, NumToMint);
        for(uint x; x < Amount; x++) { MintPackIndexes[MintPassProjectID].push(StartingTokenID + (NumArtists * x)); }
    }

    /**
     * @dev LiveMint Redeems Mint Pass If Not Already Burned & Sends Minted Work To Owner's Wallet
     */
    function _LiveMintBurn(uint TokenID) external onlyAuthorized returns (address _Recipient, uint _ArtistID)
    {
        address Recipient = IERC721(address(this)).ownerOf(TokenID);
        require(Recipient != address(0), "MintPassFactory: Invalid Recipient");
        _burn(TokenID, false);
        uint MintPassProjectID = TokenID % _ONE_MILLY;
        if(MintPasses[MintPassProjectID]._ArtBlocksProjectID == _DEFAULT) { return (Recipient, ArtistIDs[TokenID]); }
        else { return (Recipient, MintPasses[MintPassProjectID]._ArtBlocksProjectID); }
    }

    /**
     * @dev Initializes A New Mint Pass
     */
    function _InitMintPass( MintPass memory _MintPass ) external onlyAuthorized returns ( uint MintPassProjectID )
    {   
        MintPassProjectID = _TotalUniqueProjects;
        _Active[MintPassProjectID] = true;
        require(_MintPass._ArtistIDs * _MintPass._MintPacks <= _MintPass._MaxSupply, "MintPassFactory: Invalid Mint Pass Parameters");
        _MaxSupply[MintPassProjectID] = _MintPass._MaxSupply; // Internal Max Supply
        MintPasses[MintPassProjectID] = _MintPass;            // Struct Assignment
        MintPasses[MintPassProjectID]._MetadataURI = _MintPass._MetadataURI;
        if(_MintPass._ReserveAmount > 0)
        { 
            _mint(
                MintPassProjectID,       // MintPassProjectID
                _Multisig,               // Multisig
                _MintPass._ReserveAmount // Reserve Amount
            );
        }
        _TotalUniqueProjects = MintPassProjectID + 1;
        emit MintPassProjectCreated(MintPassProjectID);
        return MintPassProjectID;
    }

    /**
     * @dev Updates The BaseURI For A Project
     */
    function __NewBaseURI(uint MintPassProjectID, string memory NewURI) external onlyAuthorized 
    { 
        require(_Active[MintPassProjectID], "MintPassFactory: Mint Pass Is Not Active");
        MintPasses[MintPassProjectID]._MetadataURI = NewURI; 
    }

    /**
     * @dev Authorizes A Contract To Mint
     */
    function ____AddressAuthorize(address NewAddress) external onlyOwner { Authorized[NewAddress] = true; }

    /**
     * @dev Deauthorizes A Contract From Minting
     */
    function ___DeauthorizeContract(address NewAddress) external onlyOwner { Authorized[NewAddress] = false; }

    /**
     * @dev Overrides The Active State For A MintPassProjectID
     */
    function ____OverrideActiveState(uint MintPassProjectID, bool State) external onlyOwner { _Active[MintPassProjectID] = State; }

    /**
     * @dev Overrides The Max Supply For A MintPassProjectID
     */
    function ____OverrideMaxSupply(uint MintPassProjectID, uint NewMaxSupply) external onlyOwner 
    { 
        _MaxSupply[MintPassProjectID] = NewMaxSupply; 
        MintPasses[MintPassProjectID]._MaxSupply = NewMaxSupply;
    }

    /**
     * @dev Owner Burn Function
     */
    function ____OverrideBurn(uint[] calldata TokenIDs) external onlyOwner
    {
        for(uint x; x < TokenIDs.length; x++) { _burn(TokenIDs[x], false); }
    }

    /**
     * @dev Mints To Owner
     */
    function ___OverrideMint(uint MintPassProjectID, uint Amount) external onlyOwner
    {
        require(_Active[MintPassProjectID], "MintPassFactory: Mint Pass Is Not Active");
        _mint(MintPassProjectID, msg.sender, Amount);
    }

    /**
     * @dev Returns A MintPassProjectID From A TokenID
     */
    function ViewProjectID(uint TokenID) public pure returns (uint) { return (TokenID - (TokenID % 1000000)) / 1000000; }

    /**
     * @dev Returns The totalSupply() For A Specific MintPass ProjectID
     */
    function totalSupplyOfMintPassProjects(uint[] calldata MintPassProjectIDs) external view returns (uint[] memory)
    {
        uint[] memory Supplies = new uint[](MintPassProjectIDs.length);
        for(uint x; x < MintPassProjectIDs.length; x++)
        {
            uint MaxSupply = MintPasses[MintPassProjectIDs[x]]._MaxSupply; 
            uint Start = MintPassProjectIDs[x] * _ONE_MILLY;
            uint Range = Start + MaxSupply;
            uint Supply;
            for(Start; Start < Range; Start++) { if(_ownerships[Start].addr != address(0)) { Supply += 1; } }
        }
        return Supplies;
    }

    /**
     * @dev Returns The totalSupply() For A Specific MintPass ProjectID
     */
    function totalSupplyOfMintPassProjectID(uint MintPassProjectID) external view returns (uint)
    {
            uint MaxSupply = MintPasses[MintPassProjectID]._MaxSupply; 
            uint Start = MintPassProjectID * _ONE_MILLY;
            uint Range = Start + MaxSupply;
            uint Supply;
            for(Start; Start < Range; Start++) 
            { 
                if(_ownerships[Start].addr != address(0) || !_ownerships[Start].burned) { Supply += 1; } 
            }
    
        return Supply;
    }

    /**
     * @dev Returns Base URI Of Desired TokenID
     */
    function _baseURI(uint TokenID) internal view virtual override returns (string memory) 
    { 
        uint MintPassProjectID = ViewProjectID(TokenID);
        return MintPasses[MintPassProjectID]._MetadataURI;
        // return ILaunchpadRegistry(ILaunchpad(_LAUNCHPAD).ViewAddressLaunchpadRegistry()).ViewBaseURIMintPass(MintPassProjectID);
    }

    /**
     * @dev Access Modifier For External Smart Contracts
     * note: This Is A Custom Access Modifier That Is Used To Restrict Access To Only Authorized Contracts
     */
    modifier onlyAuthorized()
    {
        if(msg.sender != owner()) 
        { 
            require(Authorized[msg.sender], "MintPassFactory: Sender Is Not Authorized Contract"); 
        }
        _;
    }
}