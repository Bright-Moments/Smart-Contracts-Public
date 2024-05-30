//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import { MissionControl } from "./MissionControl.sol";
import { ERC721MPF } from "./ERC721MPF.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
contract MintFactoryUnified is MissionControl, ERC721MPF
{
    struct MintPassInfo
    {
        string _Name;             // [0] -> _Name
        string _Symbol;           // [1] -> _Symbol
        string _MetadataURI;      // [2] -> _MetadataURI
        uint _MaxSupply;          // [3] -> _MaxSupply
        uint _MintsPerPack;       // [4] -> _MintPacks
        uint _ArtBlocksProjectID; // [5] -> _ArtBlocksProjectID note: For Cases Where Mint Pass ProjectID 1:1 With ProjectIDs
        uint _ReserveAmount;      // [6] -> _Reserve
        address _Marketplace;     // [8] -> _Marketplace
        address _LiveMint;        // [9] -> _LiveMint
    }

    uint public _TotalUniqueProjects;  // Total Projects Invoked
    address private constant _MULTISIG = 0xB96E81f80b3AEEf65CB6d0E280b15FD5DBE71937; // test
    uint private constant _ONE_MILLY = 1_000_000; // one million boi
    uint private constant _DEFAULT = type(uint).max; // max integer
    mapping(uint => MintPassInfo) public FactoryMapping;
    mapping(uint=>uint) public ArtistIDs;
    mapping(uint=>uint[]) public MintPackIndexes;
    
    event MintPassProjectCreated(uint MintPassProjectID);
    event AuthorizedContract(address ContractAddress);
    event DeauthorizedContract(address ContractAddress);

    /**
     * @dev Mint Factory Constructor
     */
    constructor() ERC721MPF("Mint Factory | MINT", "MINT") { }

    /**
     * @dev Returns All Mint Pack Indexes
     */
    function ReadMintPackIndexes(uint MintPassProjectID) public view returns (uint[] memory) { return MintPackIndexes[MintPassProjectID]; }

    /**
     * @dev MintPass
     */
    function purchaseTo(address Recipient, uint ProjectID) external payable returns (uint NextTokenID)
    {
        NextTokenID = ReadNextTokenID(0);
        _mint(0, Recipient, 1);
        return NextTokenID;
    }

    /**
     * @dev MintPass
     */
    function purchaseToBatch(address[] calldata Recipients) external payable returns (uint[] memory MintedTokenIDs)
    {
        for(uint x; x < Recipients.length; x++)
        {
            MintedTokenIDs[x] = ReadNextTokenID(0);
            _mint(0, Recipients[x], 1);
        }
        return MintedTokenIDs;    
    }

    /**
     * @dev Direct Mint Function
     */
    function _MintToFactory(uint MintPassProjectID, address Recipient, uint Amount) external onlyAdmin
    {
        require(_Active[MintPassProjectID], "MintPass: ProjectID: `MintPassProjectID` Is Not Active");
        _mint(MintPassProjectID, Recipient, Amount);
    }

    /**
     * @dev Direct Mint To Factory Pack
     */
    function _MintToFactoryPack(uint MintPassProjectID, address Recipient, uint Amount) external onlyAdmin
    {
        require(_Active[MintPassProjectID], "MintPass: ProjectID: `MintPassProjectID` Is Not Active");
        uint NumToMintPerPack = FactoryMapping[MintPassProjectID]._MintsPerPack;
        uint NumToMint = NumToMintPerPack * Amount;
        uint StartingTokenID = ReadProjectInvocations(MintPassProjectID);
        _mint(MintPassProjectID, Recipient, NumToMint);
        for(uint x; x < Amount; x++) { MintPackIndexes[MintPassProjectID].push(StartingTokenID + (NumToMintPerPack * x)); }
    }

    /**
     * @dev LiveMint Redeems Mint Pass If Not Already Burned & Sends Minted Work To Owner's Wallet
     */
    function _LiveMintBurn(uint TokenID) external onlyAdmin returns (address _Recipient, uint _ArtistID)
    {
        address Recipient = IERC721(address(this)).ownerOf(TokenID);
        require(Recipient != address(0), "MintPass: Invalid Recipient");
        _burn(TokenID, false);
        uint MintPassProjectID = TokenID % _ONE_MILLY;
        if(FactoryMapping[MintPassProjectID]._ArtBlocksProjectID == _DEFAULT) { return (Recipient, ArtistIDs[TokenID]); }
        else { return (Recipient, FactoryMapping[MintPassProjectID]._ArtBlocksProjectID); }
    }

    /**
     * @dev Initializes Multiple Mint Passes
     */
    function __InitMintPasses(MintPassInfo[] memory _MintPasses) external onlyAdmin returns (uint[] memory MintPassProjectIDs)
    {
        MintPassProjectIDs = new uint[](_MintPasses.length);
        for(uint x; x < _MintPasses.length; x++) { MintPassProjectIDs[x] = _InitMintPass(_MintPasses[x]); }
    }

    /**
     * @dev Initializes A New Mint Pass
     */
    function __InitMintPass(MintPassInfo memory _MintPass) external onlyAdmin returns (uint MintPassProjectID) { return _InitMintPass(_MintPass); }

    /**
     * @dev Overrides A Mint Pass
     */
    function __OverrideMintPass(uint Index, MintPassInfo memory _MintPass) external onlyOwner { _OverrideMintPass(Index, _MintPass); }

    /**
     * @dev Overrides Multiple Mint Passes
     */
    function __OverrideMintPasses(uint[] calldata _Indexes, MintPassInfo[] memory _MintPasses) external onlyOwner
    {
        require(_Indexes.length == _MintPasses.length, "MintPass: Array Lengths Must Match");
        for(uint x; x < _Indexes.length; x++) { _OverrideMintPass(_Indexes[x], _MintPasses[x]); }
    }

    /**
     * @dev Updates The BaseURI For A Project
     */
    function __NewBaseURI(uint MintPassProjectID, string memory NewURI) external onlyAdmin 
    { 
        require(_Active[MintPassProjectID], "MintPass: Mint Pass Is Not Active");
        FactoryMapping[MintPassProjectID]._MetadataURI = NewURI; 
    }

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
        FactoryMapping[MintPassProjectID]._MaxSupply = NewMaxSupply;
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
        require(_Active[MintPassProjectID], "MintPass: Mint Pass Is Not Active");
        _mint(MintPassProjectID, msg.sender, Amount);
    }

    /**
     * @dev Returns A MintPassProjectID From A TokenID
     */
    function ViewProjectID(uint TokenID) public pure returns (uint) { return (TokenID - (TokenID % 1000000)) / 1000000; }

    /**
     * @dev Returns Mint Pass Info Corresponding To ProjectID
     */
    function ViewMintPassInfo(uint ProjectID) public view returns(MintPassInfo memory, uint _NextTokenID)
    {
        return (FactoryMapping[ProjectID], ReadNextTokenID(ProjectID));
    }

    /**
     * @dev Returns The totalSupply() For A Specific MintPass ProjectID
     */
    function totalSupplyOfMintPassProject(uint[] calldata MintPassProjectIDs) external view returns (uint[] memory)
    {
        uint[] memory Supplies = new uint[](MintPassProjectIDs.length);
        for(uint x; x < MintPassProjectIDs.length; x++)
        {
            uint MaxSupply = FactoryMapping[MintPassProjectIDs[x]]._MaxSupply; 
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
            uint MaxSupply = FactoryMapping[MintPassProjectID]._MaxSupply; 
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
     * @dev Internal Function To Initialize Mint Passes
     */
    function _InitMintPass( MintPassInfo memory _MintPass ) internal returns (uint MintPassProjectID)
    {
        MintPassProjectID = _TotalUniqueProjects;
        _Active[MintPassProjectID] = true;
        _MaxSupply[MintPassProjectID] = _MintPass._MaxSupply; // Internal Max Supply
        FactoryMapping[MintPassProjectID] = _MintPass;            // Struct Assignment
        FactoryMapping[MintPassProjectID]._MetadataURI = _MintPass._MetadataURI;
        if(_MintPass._ReserveAmount > 0)
        { 
            _mint(
                MintPassProjectID,       // MintPassProjectID
                _MULTISIG,               // Multisig
                _MintPass._ReserveAmount // Reserve Amount
            );
        }
        _TotalUniqueProjects = MintPassProjectID + 1;
        emit MintPassProjectCreated(MintPassProjectID);
        return MintPassProjectID;
    }

    /**
     * @dev Internal Helper Function For Overriding A Mint Pass
     */
    function _OverrideMintPass(uint Index, MintPassInfo memory _MintPass) internal
    {
        _Active[Index] = true;
        _MaxSupply[Index] = _MintPass._MaxSupply;     // Internal Max Supply
        FactoryMapping[Index] = _MintPass;            // Struct Assignment
        FactoryMapping[Index]._MetadataURI = _MintPass._MetadataURI;
        if(_MintPass._ReserveAmount > 0)
        { 
            _mint (
                Index,                   // MintPassProjectID
                _MULTISIG,               // Multisig
                _MintPass._ReserveAmount // Reserve Amount
            );
        }
    }

    /**
     * @dev Returns Base URI Of Desired TokenID
     */
    function _baseURI(uint TokenID) internal view virtual override returns (string memory) 
    { 
        uint MintPassProjectID = ViewProjectID(TokenID);
        return FactoryMapping[MintPassProjectID]._MetadataURI;
        // return ILaunchpadRegistry(ILaunchpad(_LAUNCHPAD).ViewAddressLaunchpadRegistry()).ViewBaseURIMintPass(MintPassProjectID);
    }
}