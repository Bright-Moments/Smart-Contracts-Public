//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {IERC721} from '@openzeppelin/contracts/interfaces/IERC721.sol';
import {IMPMX} from './IMPMX.sol';
contract Swapper is ReentrancyGuard
{
    struct CitizenSwap
    {
        uint OfferedTokenID;
        uint RequestedTokenID;
        uint RequestedCollectionID;
        address OfferedAddress;
        address Initiator;
        bool AnyTokenID;
        bool Complete;
    }

    struct MintPassSwap
    {
        uint OfferedTokenID;
        uint OfferedArtistID;
        uint RequestedArtistID;
        address Initiator;
        bool Complete;
    }

    struct PrivateCitizenSwap
    {
        uint OfferedTokenID;
        uint RequestedTokenID;
        uint RequestedCollection;
        address Initiator;
        address Fulfiller;
        bool Complete;
    }

    struct PrivateMintPassSwap
    {
        uint OfferedTokenID;
        uint OfferedArtistID;
        uint RequestedArtistID;
        address Initiator;
        address Fulfiller;
        bool Complete;
    }

    mapping(uint=>MintPassSwap) public MintPassPublicSwaps;
    mapping(uint=>PrivateMintPassSwap) public MintPassPrivateSwaps;
    mapping(address=>uint[]) public AddressInitiatedMintPassSwaps;
    mapping(address=>uint[]) public AddressInitiatedMintPassPrivateSwaps;

    mapping(uint=>CitizenSwap) public CitizenSwaps;
    mapping(uint=>PrivateCitizenSwap) public PrivateCitizenSwaps;
    mapping(address=>uint[]) public AddressInitiatedCitizenSwaps;
    mapping(address=>uint[]) public AddressInitiatedCitizenPrivateSwaps;

    event SwapComplete(uint PublicIndex); 
    event PrivateSwapComplete(uint PrivateIndex);

    uint public NumSwaps;
    uint public NumCitizenSwaps;
    uint public NumPrivateCitizenSwaps;
    uint public NumMintPassPrivateSwaps;
    uint public NumMintPassSwaps;
    address MintPass = address(0);

    /**
     * @dev Requests Public Mint Pass Swap
     */
    function RequestPublicMintPassSwap(
        uint OfferedTokenID, 
        uint RequestedArtistID
    ) external nonReentrant {
        require(
            IERC721(MintPass).ownerOf(OfferedTokenID)
            ==
            msg.sender,
            "Initiator Does Not Own OfferedTokenID"
        );
        MintPassPublicSwaps[NumMintPassSwaps] = MintPassSwap(
            OfferedTokenID, 
            IMPMX(MintPass).ViewArtistID(OfferedTokenID),
            RequestedArtistID, 
            msg.sender, 
            false
        );
        AddressInitiatedCitizenSwaps[msg.sender].push(NumMintPassSwaps);
        NumMintPassSwaps++;
    }

    /**
     * @dev Requests Private Swap
     */
    function RequestPrivateMintPassSwap(
        uint OfferedTokenID, 
        uint RequestedArtistID, 
        address Fulfiller
    ) external nonReentrant {
        require(msg.sender == IERC721(MintPass).ownerOf(OfferedTokenID), "`msg.sender` Does Not Own TokenID");
        MintPassPrivateSwaps[NumMintPassPrivateSwaps] = PrivateMintPassSwap(
            OfferedTokenID,                               // OfferedTokenID
            IMPMX(MintPass).ViewArtistID(OfferedTokenID), // Offered ArtistID
            RequestedArtistID,                            // Requested ArtistID
            msg.sender,                                   // Initiator
            Fulfiller,                                    // Private Fulfiller
            false                                         // IsComplete
        );
        AddressInitiatedMintPassPrivateSwaps[msg.sender].push(NumMintPassPrivateSwaps);
        NumMintPassPrivateSwaps++;
    }

    /**
     * @dev Requests A Public Citizen Swap
     * note: CollectionID Corresponds To The City #
     * note: 0 = Galactican
     * note: 1 = Venetian
     * note: 2 = NewYorker
     * etc...
     */
    function RequestPublicCitizenSwap(
        uint OfferedTokenID,
        uint RequestedTokenID,
        uint RequestedCollectionID,
        bool AnyTokenID
    ) external nonReentrant {
        address Collection = DeriveCollection(OfferedTokenID);
        require(
            IERC721(Collection).ownerOf(OfferedTokenID)
            ==
            msg.sender,
            "Initiator Does Not Own OfferedTokenID"
        );
        CitizenSwaps[NumCitizenSwaps] = CitizenSwap(
            OfferedTokenID, 
            RequestedTokenID,
            RequestedCollectionID, 
            DeriveCollection(OfferedTokenID),
            msg.sender, 
            AnyTokenID,
            false
        );
        AddressInitiatedCitizenSwaps[msg.sender].push(NumCitizenSwaps);
        NumCitizenSwaps++;
    }

    /**
     * @dev Executes Swap
     */
    function ExecutePublicSwapMintPass(uint Index, uint TokenID) external nonReentrant
    {
        require(!MintPassPublicSwaps[Index].Complete, "Swap Already Complete");
        require(msg.sender != MintPassPublicSwaps[Index].Initiator, "Message Sender Is Initiator");
        require(MintPassPublicSwaps[Index].RequestedArtistID == IMPMX(MintPass).ViewArtistID(TokenID), "Incorrect ArtistID");
        require(
            IERC721(MintPass).ownerOf(MintPassPublicSwaps[Index].OfferedTokenID) 
            == 
            MintPassPublicSwaps[Index].Initiator,
            "Swapper: Initiator Does Not Own Base OfferedTokenID"
        );
        require(
            IERC721(MintPass).ownerOf(TokenID) 
            == 
            msg.sender,
            "Swapper: Fulfiller Does Not Own TokenID"
        );
        IERC721(MintPass).transferFrom(
            msg.sender,
            MintPassPublicSwaps[Index].Initiator, 
            TokenID
        );
        IERC721(MintPass).transferFrom(
            MintPassPublicSwaps[Index].Initiator, 
            msg.sender, 
            MintPassPublicSwaps[Index].OfferedTokenID
        );
        require(
            IERC721(MintPass).ownerOf(TokenID) == MintPassPublicSwaps[Index].Initiator, 
            "Swapper: Initiator Does Not Own Swapped TokenID"
        );
        require(
            IERC721(MintPass).ownerOf(MintPassPublicSwaps[Index].OfferedTokenID) == msg.sender, 
            "Swapper: Fulfiller Does Not Own Base OfferedTokenID"
        );
        MintPassPublicSwaps[Index].Complete = true;
        emit PrivateSwapComplete(Index);
    }

    /**
     * @dev Executes Swap
     */
    function ExecutePrivateSwapMintPass(uint Index, uint TokenID) external nonReentrant
    {
        require(!MintPassPrivateSwaps[Index].Complete, "Swap Already Complete");
        require(msg.sender == MintPassPrivateSwaps[Index].Fulfiller, "Message Sender Is Not Fulfiller");
        require(MintPassPrivateSwaps[Index].RequestedArtistID == IMPMX(MintPass).ViewArtistID(TokenID), "Incorrect ArtistID");
        require(
            IERC721(MintPass).ownerOf(MintPassPrivateSwaps[Index].OfferedTokenID) 
            == 
            MintPassPrivateSwaps[Index].Initiator,
            "Swapper: Initiator Does Not Own Base OfferedTokenID"
        );
        require(
            IERC721(MintPass).ownerOf(TokenID) 
            == 
            MintPassPrivateSwaps[Index].Fulfiller, 
            "Swapper: Fulfiller Does Not Own Requested OfferedTokenID"
        );
        IERC721(MintPass).transferFrom(
            MintPassPrivateSwaps[Index].Fulfiller, 
            MintPassPrivateSwaps[Index].Initiator, 
            TokenID
        );
        IERC721(MintPass).transferFrom(
            MintPassPrivateSwaps[Index].Initiator, 
            MintPassPrivateSwaps[Index].Fulfiller, 
            MintPassPrivateSwaps[Index].OfferedTokenID
        );
        require(
            IERC721(MintPass).ownerOf(TokenID) == MintPassPrivateSwaps[Index].Initiator, 
            "Swapper: Initiator Does Not Own Requested OfferedTokenID"
        );
        require(
            IERC721(MintPass).ownerOf(MintPassPrivateSwaps[Index].OfferedTokenID) == MintPassPrivateSwaps[Index].Fulfiller, 
            "Swapper: Fulfiller Does Not Own Base OfferedTokenID"
        );
        MintPassPrivateSwaps[Index].Complete = true;
        emit PrivateSwapComplete(Index);
    }

    /**
     * @dev Returns Address Of Collection
     */
    function DeriveCollection(uint TokenID) public view returns(address)
    {
        
    }

    /**
     * @dev Returns Active Swap Indexes
     */
    function ViewActivePublicMintPassSwapIndexes(
        uint StartingIndex, 
        uint EndingIndex
    ) public view returns(uint[] memory) {
        uint[] memory ActiveIndexes = new uint[](EndingIndex-StartingIndex);
        uint Counter;
        for(uint x = StartingIndex; x <= EndingIndex; x++)
        {
            if(!MintPassPublicSwaps[x].Complete) { ActiveIndexes[Counter] = x; }
            Counter++;
        }
        uint[] memory FormattedActiveIndexes = new uint[](Counter);
        for(uint y; y < Counter; y++)
        {
            FormattedActiveIndexes[y] = ActiveIndexes[y];
        }
        return FormattedActiveIndexes;
    }

    /**
     * @dev Returns Active Swap Indexes
     */
    function ViewActivePrivateMintPassSwapIndexes(
        uint StartingIndex, 
        uint EndingIndex
    ) public view returns(uint[] memory) {
        uint[] memory ActiveIndexes = new uint[](EndingIndex-StartingIndex);
        uint Counter;
        for(uint x = StartingIndex; x <= EndingIndex; x++)
        {
            if(!MintPassPrivateSwaps[x].Complete) { ActiveIndexes[Counter] = x; }
            Counter++;
        }
        uint[] memory FormattedActiveIndexes = new uint[](Counter);
        for(uint y; y < Counter; y++)
        {
            FormattedActiveIndexes[y] = ActiveIndexes[y];
        }
        return FormattedActiveIndexes;
    }

    /**
     * @dev Returns Tuple Of Wallet Initiated Swaps
     */
    function ViewWalletInitiatedSwaps(address Wallet) public view returns(
        uint[] memory, // Public Mint Pass Swaps
        uint[] memory, // Private Mint Pass Swaps
        uint[] memory, // Public Citizen Swaps
        uint[] memory  // Private Citizen Swaps
    ) {
        return(
            AddressInitiatedMintPassSwaps[Wallet],
            AddressInitiatedMintPassPrivateSwaps[Wallet],
            AddressInitiatedCitizenSwaps[Wallet],
            AddressInitiatedCitizenPrivateSwaps[Wallet]
        );
    }
}