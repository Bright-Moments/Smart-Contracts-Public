// //SPDX-License-Identifier: MIT
// pragma solidity 0.8.19;
// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
// import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {CTZNPlugin, ICTZN} from "./CTZNPlugin.sol";
// import {IMP} from "./IMP.sol";
// contract DutchRefunder is Ownable, ReentrancyGuard, CTZNPlugin
// {    
//     struct Sale
//     {
//         // Initializers
//         address ContractAddress;
//         uint PriceStart;
//         uint PriceEnd;
//         uint UserPurchaseableAmount;
//         uint MaximumAvailableForSalePublic;
//         uint MaximumAvailableForSaleBrightList;
//         uint StartingBlockTimestamp;
//         uint SecondsBetweenPriceDecay;
//         bool AllowMultiplePurchases;
//         bool Active;
//         bool BrightListActive;
//         bytes32 Root; 
//     }

//     struct InternalSale
//     {
//         // Owner / Automated
//         bool ClaimsEnabled;
//         bool ArtistIDsSeeded;
//         uint AmountSold;
//         uint FinalClearingPrice;

//         // Non-Editable
//         uint SaleProceeds;
//     }

//     struct SaleMintPack
//     {
//         address ContractAddress;
//         uint PriceStart;
//         uint PriceEnd;
//         uint UserPurchaseableAmount;
//         uint MaximumAvailableForSalePublic;
//         uint MaximumAvailableForSaleBrightList;
//         uint StartingBlockTimestamp;
//         uint SecondsBetweenPriceDecay;
//         bool ActivePublic;
//         bool ActiveBrightList;
//         bool AllowMultiplePurchases;
//     }
    
//     struct InternalSaleMintPack
//     {
//         //Owner / Automated
//         uint AmountSold;
//         uint FinalClearingPrice;
//         uint _MintPackIndex;

//         // Non-Editable
//         uint SaleProceeds;
//     }

//     address GoldenToken = address(0);
//     address Option = address(0);
//     address private immutable BURN_ADDRESS = 0xcff43A597911a9457071d89d2b2AC3D5b1862b86; // mint.brightmoments.eth

//     mapping(uint=>Sale) public Sales;
//     mapping(uint=>SaleMintPack) public MintPackSales;
//     mapping(uint=>InternalSale) public InternalSales;
//     mapping(uint=>InternalSaleMintPack) public InternalSalesMintPack;
//     mapping(uint=>mapping(address=>uint[])) public AddressToOrderIndex;
//     mapping(uint=>mapping(uint=>uint)) public OrderToArtistID;
//     mapping(uint=>mapping(uint=>address)) public ContractAddresses;
//     mapping(uint=>mapping(address=>uint)) public UserClaimedIndex;
//     mapping(uint=>mapping(address=>uint)) public UserPurchaseValue;
//     mapping(uint=>mapping(address=>uint)) public UserPurchasedAmount;
//     mapping(uint=>mapping(address=>bool)) public UserPurchasedSale;
//     mapping(uint=>mapping(uint=>bool)) public RedeemedGoldenToken;

//     event Purchased(address Recipient, uint SaleIndex, uint Amount, uint MessageValue);
//     event OptionClaimed(uint SaleIndex, address Redeemer, uint[] TokenIDs);
//     event RefundClaimed(address Recipient, uint RefundAmount);
//     event MintPassesClaimed(address Recipient, uint Amount);
//     event MerkleRootChanged(bytes32 OldRoot, bytes32 NewRoot);
//     event RandomArtistIDsSeeded(uint SaleIndexChanged, uint8[] ArtistIDs);
//     event ClaimStateSwitched(uint SaleIndexChanged, bool State);
//     event ContractAddressSeeded(uint SaleIndexChanged, address ContractAddress);
//     event ClaimsDisabled(uint SaleIndexChanged);

//     constructor()
//     { 
//         Sales[0] = Sale( // Instantiates New Sale With Initializer Variables
//             address(0),  // ContractAddress
//             20 ether,    // PriceStart
//             1 ether,     // PriceEnd
//             1,           // UserPurchaseableAmount
//             750,         // MaximumAvailableForSalePublic
//             750,         // MaximumAvailableForSaleBrightList
//             123456789,   // StartingBlockTimestamp
//             840,         // SecondsBetweenPriceDecay
//             true,        // AllowMultiplePurchases
//             true,        // ActivePublic
//             true,        // ActiveBrightList
//             0x0          // Root
//         );

//         MintPackSales[0] = SaleMintPack(
//             address(0), // ContractAddress
//             200 ether,  // PriceStart
//             10 ether,   // PriceEnd
//             1,          // UserPurchaseableAmount
//             10,         // MaximumAvailableForSalePublic
//             10,         // MaximumAvailableForSaleBrightList
//             123456789,  // StartingBlockTimestamp
//             840,        // Seconds Between Price Decay
//             true,       // ActivePublic
//             true,       // ActiveBrightList
//             true        // AllowMultiplePurchases
//         );

//         // Instantiates New $CTZN Reward Rates
//         _RewardRates[0] = 75 ether;  // RewardRates[0] = BRIGHTLIST MINT PACK PURCHASE
//         _RewardRates[1] = 50 ether;  // RewardRates[1] = BRIGHTLIST MINT PASS PURCHASE
//         _RewardRates[2] = 50 ether;  // RewardRates[2] = PUBLIC MINT PACK PURCHASE
//         _RewardRates[3] = 25 ether;  // RewardRates[3] = PUBLIC MINT PASS PURCHASE
//         _transferOwnership(0xe06F5FAE754e81Bc050215fF89B03d9e9FF20700); // operator.brightmoments.eth
//     } 

//     /*-------------------
//      * PUBLIC FUNCTIONS *
//     --------------------*/

//     /**
//      * @dev Purchases NFTs
//      */
//     function Purchase(uint SaleIndex, uint Amount) public payable nonReentrant
//     { 
//         require(block.timestamp >= Sales[SaleIndex].StartingBlockTimestamp, "Sale Not Started Yet");
//         require(Sales[SaleIndex].Active, "Sale Index Is Not Active");
//         require(InternalSales[SaleIndex].AmountSold + Amount <= Sales[SaleIndex].MaximumAvailableForSalePublic, "Sold Out");
//         require(UserPurchasedAmount[SaleIndex][msg.sender] + Amount <= Sales[SaleIndex].UserPurchaseableAmount, "User Has Used Up All Allocation For This Sale Index");
//         uint CurrentPrice = ViewCurrentDutchPrice(SaleIndex);
//         require(msg.value == CurrentPrice * Amount, "Incorrect Ether Amount");
//         require(Amount > 0, "Invalid Amount");
//         if(InternalSales[SaleIndex].AmountSold + Amount == Sales[SaleIndex].MaximumAvailableForSalePublic) { InternalSales[SaleIndex].FinalClearingPrice = CurrentPrice; }
//         if(!Sales[SaleIndex].AllowMultiplePurchases) { require(!UserPurchasedSale[SaleIndex][msg.sender], "User Has Already Purchased This Sale Index"); }
//         if(!UserPurchasedSale[SaleIndex][msg.sender]) { UserPurchasedSale[SaleIndex][msg.sender] = true; }
//         for(uint x; x < Amount; x++) 
//         { 
//             AddressToOrderIndex[SaleIndex][msg.sender].push(InternalSales[SaleIndex].AmountSold);
//             InternalSales[SaleIndex].AmountSold++;
//         }
//         UserPurchasedAmount[SaleIndex][msg.sender] += Amount;
//         UserPurchaseValue[SaleIndex][msg.sender] += msg.value;
//         InternalSales[SaleIndex].SaleProceeds += msg.value;
//         ICTZN(CTZN).IncrementCTZN(msg.sender, _RewardRates[0]); // Increments $CTZN Rewards
//         emit Purchased(msg.sender, SaleIndex, Amount, msg.value);
//     }

//     /**
//      * @dev Purchases NFTs
//      */
//     function PurchaseBrightList(uint SaleIndex, uint Amount, bytes32[] calldata Proof) public payable nonReentrant
//     { 
//         require(Sales[SaleIndex].BrightListActive, "Requested Sale Is Not Available For Purchases");
//         require(InternalSales[SaleIndex].AmountSold + Amount <= Sales[SaleIndex].MaximumAvailableForSalePublic, "Sold Out");
//         require(UserPurchasedAmount[SaleIndex][msg.sender] + Amount <= Sales[SaleIndex].UserPurchaseableAmount, "User Has Used Up All Allocation For This Sale Index");
//         require(VerifyBrightList(SaleIndex, msg.sender, Proof), "User Is Not On BrightList");
//         uint CurrentPrice = ViewCurrentDutchPrice(SaleIndex);
//         if(InternalSales[SaleIndex].AmountSold + Amount == Sales[SaleIndex].MaximumAvailableForSalePublic) { InternalSales[SaleIndex].FinalClearingPrice = CurrentPrice; }
//         if(!Sales[SaleIndex].AllowMultiplePurchases) { require(!UserPurchasedSale[SaleIndex][msg.sender], "User Has Already Purchased This Sale Index"); }
//         require(msg.value == CurrentPrice * Amount && Amount > 0, "Incorrect Ether Amount Or Token Amount Sent For Purchase");
//         if(!UserPurchasedSale[SaleIndex][msg.sender]) { UserPurchasedSale[SaleIndex][msg.sender] = true; }
//         for(uint x; x < Amount; x++) 
//         { 
//             AddressToOrderIndex[SaleIndex][msg.sender].push(InternalSales[SaleIndex].AmountSold);
//             InternalSales[SaleIndex].AmountSold++;
//         }
//         UserPurchasedAmount[SaleIndex][msg.sender] += Amount;
//         UserPurchaseValue[SaleIndex][msg.sender] += msg.value;
//         InternalSales[SaleIndex].SaleProceeds += msg.value;
//         ICTZN(CTZN).IncrementCTZN(msg.sender, _RewardRates[1]); // Increments $CTZN
//         emit Purchased(msg.sender, SaleIndex, Amount, msg.value);
//     }

//     /**
//      * @dev Purchases 
//      */
//     function PurchaseMintPackPublic(uint SaleIndex, uint Amount) public payable nonReentrant
//     {
//         require(MintPackSales[SaleIndex].ActivePublic, "Sale Is Not Active For Public Purchases");
//         require(block.timestamp >= MintPackSales[SaleIndex].StartingBlockTimestamp, "Sale Has Not Started");
//         require(
//             UserPurchasedAmount[SaleIndex][msg.sender] + Amount <= MintPackSales[SaleIndex].MaximumAvailableForSalePublic, 
//             "User Has Used Up All Allocation For This Sale Index"
//         );
//         uint CurrentPrice = ViewCurrentDutchPriceMintPack(SaleIndex);
//         if(InternalSalesMintPack[SaleIndex].AmountSold + Amount == MintPackSales[SaleIndex].MaximumAvailableForSalePublic) 
//         { 
//             InternalSalesMintPack[SaleIndex].FinalClearingPrice = CurrentPrice; 
//         }
//         if(!MintPackSales[SaleIndex].AllowMultiplePurchases) 
//         { 
//             require(!UserPurchasedSale[SaleIndex][msg.sender], "User Has Already Purchased This Sale Index"); 
//         }
//         require(msg.value == CurrentPrice * Amount && Amount > 0, "Incorrect Ether Amount Or Token Amount Sent For Purchase");
//         if(!UserPurchasedSale[SaleIndex][msg.sender]) { UserPurchasedSale[SaleIndex][msg.sender] = true; }
//         for(uint x; x < 10; x++)
//         {
//             IERC721(address(0)).transferFrom(address(this), msg.sender, InternalSalesMintPack[SaleIndex]._MintPackIndex);
//             InternalSalesMintPack[SaleIndex]._MintPackIndex++;
//         }
//         InternalSalesMintPack[SaleIndex].SaleProceeds += msg.value;
//         ICTZN(CTZN).IncrementCTZN(msg.sender, _RewardRates[1]); // Increments $CTZN
//         emit Purchased(msg.sender, SaleIndex, Amount, msg.value);
//     }

//     /**
//      * @dev Purchases Mint Pass
//      */
//     function PurchaseMintPackBrightList(uint SaleIndex, uint Amount, bytes32[] calldata Proof) public payable nonReentrant
//     {
//         require(MintPackSales[SaleIndex].ActiveBrightList, "BrightList Sale Not Active");
//         require(InternalSalesMintPack[SaleIndex].AmountSold + Amount <= MintPackSales[SaleIndex].MaximumAvailableForSaleBrightList, "Sold Out");
//         require(block.timestamp >= MintPackSales[SaleIndex].StartingBlockTimestamp, "Sale Has Not Started");
//         require(
//             UserPurchasedAmount[SaleIndex][msg.sender] + Amount <= MintPackSales[SaleIndex].MaximumAvailableForSaleBrightList, 
//             "User Has Used Up All Allocation For This Sale Index"
//         );
//         require(VerifyBrightList(SaleIndex, msg.sender, Proof), "User Is Not On BrightList");
//         uint CurrentPrice = ViewCurrentDutchPrice(SaleIndex);
//         if(InternalSalesMintPack[SaleIndex].AmountSold + Amount == MintPackSales[SaleIndex].MaximumAvailableForSaleBrightList) 
//         { 
//             InternalSalesMintPack[SaleIndex].FinalClearingPrice = CurrentPrice; 
//         }
//         if(!MintPackSales[SaleIndex].AllowMultiplePurchases) 
//         { 
//             require(!UserPurchasedSale[SaleIndex][msg.sender], "User Has Already Purchased This Sale Index"); 
//         }
//         require(msg.value == CurrentPrice * Amount && Amount > 0, "Incorrect Ether Amount Or Token Amount Sent For Purchase");
//         if(!UserPurchasedSale[SaleIndex][msg.sender]) { UserPurchasedSale[SaleIndex][msg.sender] = true; }
//         for(uint x; x < 10; x++)
//         InternalSalesMintPack[SaleIndex].SaleProceeds += msg.value;
//         ICTZN(CTZN).IncrementCTZN(msg.sender, _RewardRates[1]); // Increments $CTZN rewards
//         emit Purchased(msg.sender, SaleIndex, Amount, msg.value);
//     }

//     /**
//      * @dev Allows User To Claim Refund And Mint Passes
//      */
//     function ClaimPurchasedNFTs(uint SaleIndex) public nonReentrant
//     {
//         require(InternalSales[SaleIndex].ClaimsEnabled, "Mint Passes & Refund Claiming Will Be Enabled When The Sale Completes");
//         require(
//             UserPurchaseValue[SaleIndex][msg.sender] > 0
//             &&
//             UserPurchasedAmount[SaleIndex][msg.sender] > 0,
//             "DutchRefunder: No Eligible Claim"
//         );

//         /**
//          * @dev Refunds User Based On DA Clearing Price
//          */
//         uint RefundAmount = UserPurchaseValue[SaleIndex][msg.sender] - InternalSales[SaleIndex].FinalClearingPrice;
//         UserPurchaseValue[SaleIndex][msg.sender] = 0;
//         payable(msg.sender).transfer(RefundAmount); 
//         emit RefundClaimed(msg.sender, RefundAmount);
            
//         /**
//          * @dev Allocates Mint Passes
//          */
//         uint _UserPurchasedAmount = UserPurchasedAmount[SaleIndex][msg.sender];
//         UserPurchasedAmount[SaleIndex][msg.sender] = 0;
//         for(uint i; i < _UserPurchasedAmount; i++)
//         {
//             // This Implementation Assumes Separate Artist Contracts
//             // This Mapping Ensures That The User Always Receives Their Correct ArtistIDs Irrespective Of When They Claim
//             // IMP(Sales[SaleIndex].ContractAddresses
//             // [
//             //     OrderToArtistID[SaleIndex]
//             //     [
//             //         AddressToOrderIndex[SaleIndex][msg.sender]
//             //         [
//             //             UserClaimedIndex[SaleIndex][msg.sender]
//             //         ]
//             //     ]
//             // ]).purchaseTo(msg.sender);`

//             // This Implementation Assumes 1 Shared Contract Address With Different ArtistID Ranges
//             // The Mapping Ensures That The User Always Receives Their Correct ArtistIDs Irrespective Of When They Claim
//             IMP(Sales[SaleIndex].ContractAddress).purchaseTo(
//                 msg.sender, // Recipient
//                 OrderToArtistID[SaleIndex] // ArtistID
//                     [
//                         AddressToOrderIndex[SaleIndex][msg.sender]
//                         [
//                             UserClaimedIndex[SaleIndex][msg.sender]
//                         ]
//                     ]
//             );
//             UserClaimedIndex[SaleIndex][msg.sender]++;
//         }
//         emit MintPassesClaimed(msg.sender, _UserPurchasedAmount);
//     }

//     /**
//      * @dev Claims NFT Option
//      */
//     function ClaimOption(uint SaleIndex, uint[] calldata TokenIDs) external nonReentrant
//     {
//         for(uint TokenID; TokenID < TokenIDs.length; TokenID++)
//         {
//             require(IERC721(GoldenToken).ownerOf(TokenIDs[TokenID]) == msg.sender, "User Is Not Owner Of Golden Token");
//             require(!RedeemedGoldenToken[SaleIndex][TokenIDs[TokenID]], "Golden Token Already Redeemed");
//             RedeemedGoldenToken[SaleIndex][TokenIDs[TokenID]] = true;
//             IMP(Option).claimOption(msg.sender);
//             emit OptionClaimed(SaleIndex, msg.sender, TokenIDs);
//         }
//     }

//     /**
//      * @dev Redeems NFT Option
//      */
//     function RedeemOption(uint SaleIndex, uint[] calldata TokenIDs) external payable nonReentrant
//     {
//         require(msg.value == ViewCurrentDutchPrice(SaleIndex), "DutchRefunder: Invalid Message Value");
//         require(InternalSales[SaleIndex].FinalClearingPrice > 0, "Sale Has Not Concluded");
//         for(uint TokenID; TokenID < TokenIDs.length; TokenID++)
//         {
//             require(IERC721(Option).ownerOf(TokenIDs[TokenID]) == msg.sender, "ERC721: User Does Not Own TokenID");
//             IERC721(Option).transferFrom(msg.sender, BURN_ADDRESS, TokenIDs[TokenID]);
//             IMP(Sales[SaleIndex].ContractAddress).purchaseTo(
//                 msg.sender, // Recipient
//                 OrderToArtistID[SaleIndex][TokenIDs[TokenID]] // ArtistID
//             );
//             require(IERC721(Option).ownerOf(TokenIDs[TokenID]) == BURN_ADDRESS, "ERC721: Error Redeeming Option");
//             emit MintPassesClaimed(msg.sender, TokenIDs.length);
//         }
//     }

//     /*------------------
//      * ADMIN FUNCTIONS *
//     -------------------*/

//     /**
//      * @dev Initializes Sale
//      */
//     function __InitSale(
//         uint SaleIndexToSeed,
//         uint PriceStart,
//         uint PriceEnd,
//         uint UserPurchaseableAmount,
//         uint MaximumAvailableForSalePublic,
//         uint StartingBlockTimestamp,
//         uint SecondsBetweenPriceDecay,
//         bool AllowMultiplePurchases,
//         bool Active,
//         bytes32 Root
//     ) external onlyOwner {
//         Sales[SaleIndexToSeed].PriceStart = PriceStart;
//         Sales[SaleIndexToSeed].PriceEnd = PriceEnd;
//         Sales[SaleIndexToSeed].UserPurchaseableAmount = UserPurchaseableAmount;
//         Sales[SaleIndexToSeed].MaximumAvailableForSalePublic = MaximumAvailableForSalePublic;
//         Sales[SaleIndexToSeed].StartingBlockTimestamp = StartingBlockTimestamp;
//         Sales[SaleIndexToSeed].SecondsBetweenPriceDecay = SecondsBetweenPriceDecay;
//         Sales[SaleIndexToSeed].AllowMultiplePurchases = AllowMultiplePurchases;
//         Sales[SaleIndexToSeed].Active = Active;
//         Sales[SaleIndexToSeed].Root = Root;
//     }

//     /**
//      * @dev Changes Ending Price For A Sale
//      */
//     function __ChangeEndingPrice(uint SaleIndexToSeed, uint PriceEnd) external onlyOwner 
//     { 
//         Sales[SaleIndexToSeed].PriceEnd = PriceEnd; 
//     }

//     /**
//      * @dev Changes Final Settlement Price For A Sale
//      */
//     function __OverrideClearingPrice(uint SaleIndexToSeed, uint FinalClearingPrice) external onlyOwner 
//     { 
//         InternalSales[SaleIndexToSeed].FinalClearingPrice = FinalClearingPrice; 
//     }

//     /**
//      * @dev Enables Claims
//      */
//     function __EnableClaims(uint SaleIndexToSeed) external onlyOwner 
//     { 
//         require(InternalSales[SaleIndexToSeed].FinalClearingPrice > 0, "Sale Has Not Settled");
//         require(InternalSales[SaleIndexToSeed].ArtistIDsSeeded, "Random ArtistIDs Not Instantiated");
//         InternalSales[SaleIndexToSeed].ClaimsEnabled = true; 
//         emit ClaimStateSwitched(SaleIndexToSeed, true);
//     }

//     /**
//      * @dev Disables Claims
//      */
//     function __DisableClaims(uint SaleIndexToSeed) external onlyOwner 
//     { 
//         InternalSales[SaleIndexToSeed].ClaimsEnabled = false; 
//         emit ClaimsDisabled(SaleIndexToSeed);
//     }

//     /**
//      * @dev Seeds Random ArtistIDs For A Sale
//      */
//     function __SeedRandomArtistIDs(uint SaleIndexToSeed, uint8[] calldata ArtistIDs) external onlyOwner
//     {
//         for(uint i; i < ArtistIDs.length; i++)
//         {
//             OrderToArtistID[SaleIndexToSeed][i] = ArtistIDs[i];
//         }
//         InternalSales[SaleIndexToSeed].ArtistIDsSeeded = true;
//         emit RandomArtistIDsSeeded(SaleIndexToSeed, ArtistIDs);
//     }

//     /**
//      * @dev Seeds Contract Addresses For a Specific Sale Index
//      */
//     function __SeedContractAddresses(uint SaleIndexToSeed, address ContractAddress) external onlyOwner
//     {
//         Sales[SaleIndexToSeed].ContractAddress = ContractAddress;
//         emit ContractAddressSeeded(SaleIndexToSeed, ContractAddress);
//     }

//     /**
//      * @dev Withdraws Ether From Contract To Address With An Amount
//      * note: OnlyOwner
//      * note: `Amount` is Denoted In WEI ()
//      */
//     function __WithdrawEther(address payable Recipient, uint Amount) external onlyOwner
//     {
//         require(Amount > 0 && Amount <= address(this).balance, "Invalid Amount");
//         (bool Success, ) = Recipient.call{value: Amount}("");
//         require(Success, "Unable to Withdraw, Recipient May Have Reverted");
//     }

//     /**
//      * @dev Withdraws All Ether From The Contract
//      */
//     function __Withdraw() external onlyOwner { payable(msg.sender).transfer(address(this).balance); }

//     /**
//      * @dev Changes Merkle Root
//      */
//     function __NewRoot(uint SaleIndexToChange, bytes32 NewRoot) external onlyOwner
//     {
//         bytes32 OldRoot = Sales[SaleIndexToChange].Root;
//         Sales[SaleIndexToChange].Root = NewRoot;
//         emit MerkleRootChanged(OldRoot, NewRoot);
//     }

//     /**
//      * @dev Instantiates New Golden Token Address
//      */
//     function __NewGoldenTokenAddress(address NewAddress) external onlyOwner { GoldenToken = NewAddress; }

//     /**
//      * @dev Instantiates New Golden Token Address
//      */
//     function __NewOptionAddress(address NewAddress) external onlyOwner { Option = NewAddress; }

//     /*-----------------
//      * VIEW FUNCTIONS *
//     ------------------*/

//     /**
//      * @dev Returns If User Is On BrightList
//      */
//     function VerifyBrightList(uint SaleIndex, address Recipient, bytes32[] calldata Proof) public view returns(bool Status)
//     {
//         bytes32 Leaf = keccak256(abi.encodePacked(Recipient));
//         return MerkleProof.verify(Proof, Sales[SaleIndex].Root, Leaf);
//     }

//     /**
//      * @dev Returns Current Dutch Price
//      */
//     function ViewCurrentDutchPrice(uint SaleIndex) public view returns (uint Price) 
//     {
//         uint CurrentPrice = Sales[SaleIndex].PriceStart;
//         uint BlocksElapsed = block.timestamp - Sales[SaleIndex].StartingBlockTimestamp;
//         CurrentPrice >>= BlocksElapsed / Sales[SaleIndex].SecondsBetweenPriceDecay; // Div/2 For Each Half Life Iterated Via Bitshift
//         CurrentPrice -= (CurrentPrice * (BlocksElapsed % Sales[SaleIndex].SecondsBetweenPriceDecay)) / Sales[SaleIndex].SecondsBetweenPriceDecay / 2;
//         if(InternalSales[SaleIndex].FinalClearingPrice > 0) { return InternalSales[SaleIndex].FinalClearingPrice; } // Sale Finished
//         else if (CurrentPrice <= Sales[SaleIndex].PriceEnd) { return Sales[SaleIndex].PriceEnd; } // Sale Ended At Resting Band
//         else { return CurrentPrice; } // Sale Currently Active
//     }

//     /**
//      * @dev Returns Current Dutch Price
//      */
//     function ViewCurrentDutchPriceMintPack(uint SaleIndex) public view returns (uint Price) 
//     {
//         uint CurrentPrice = Sales[SaleIndex].PriceStart;
//         uint BlocksElapsed = block.timestamp - Sales[SaleIndex].StartingBlockTimestamp;
//         CurrentPrice >>= BlocksElapsed / Sales[SaleIndex].SecondsBetweenPriceDecay; // Div/2 For Each Half Life Iterated Via Bitshift
//         CurrentPrice -= (CurrentPrice * (BlocksElapsed % Sales[SaleIndex].SecondsBetweenPriceDecay)) / Sales[SaleIndex].SecondsBetweenPriceDecay / 2; 
//         if(InternalSales[SaleIndex].FinalClearingPrice > 0) { return InternalSales[SaleIndex].FinalClearingPrice; } // Sale Finished
//         else if (CurrentPrice <= Sales[SaleIndex].PriceEnd) { return Sales[SaleIndex].PriceEnd; } // Sale Ended At Resting Band
//         else { return CurrentPrice; } // Sale Currently Active
//     }
// }