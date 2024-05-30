// contract TimeRandomizer
// {
//     struct Randomizer
//     {
//         uint StartTime;
//         uint IntervalInMilliseconds;
//         uint NumTokenIDs;
//         uint Randomness;
//     }

//     uint _CurrentIndex;
//     mapping(uint=>uint) public CurrentDrawIndex;
//     mapping(uint=>uint) public CurrentDrawIndexTimes;
//     mapping(uint=>Randomizer) public Randomizers;
//     mapping(uint=>uint[]) public RandomizedIDs;
//     mapping(uint=>uint[]) public RandomizedTimes;
//     mapping(uint=>mapping(uint=>bool)) public RandomizedIDExists;
//     mapping(uint=>mapping(uint=>bool)) public RandomizedTimeExists;

//     /**
//      * @dev Initializes A Randomizer
//      */
//     function Init(uint StartDay, uint StartHour, uint StartMinute, uint IntervalInMinutes, uint NumTokenIDs, uint Randomness) external
//     {
//         uint IntervalInMilliseconds = IntervalInMinutes * 60 * 1000;
//         Randomizers[_CurrentIndex] = Randomizer(UnixStartTime, IntervalInMilliseconds, NumTokenIDs, Randomness);
//         _CurrentIndex += 1;
//     }
    
//     /**
//      * @dev Randomizes IDs For A Project
//      */
//     function RandomizeIDs(uint ProjectID, uint Amount) public
//     {
//         uint Range = Randomizers[_CurrentIndex].NumTokenIDs;
//         uint _CurrentDrawIndex = CurrentDrawIndex[ProjectID];
//         for(uint x; x < Amount; x++)
//         {
//             uint RandomID = uint(keccak256(abi.encodePacked(_CurrentDrawIndex, Randomizers[_CurrentIndex].Randomness))) % Range;
//             if(!RandomizedIDExists[ProjectID][RandomID])
//             {
//                 RandomizedIDs[ProjectID].push(RandomID);
//                 RandomizedIDExists[ProjectID][RandomID] = true;
//                 _CurrentDrawIndex += 1;
//             }
//         }
//         CurrentDrawIndex[ProjectID] = _CurrentDrawIndex;
//     }

//     /**
//      * @dev Randomizes Times For A Project
//      */
//     function RandomizeTimes(uint ProjectID, uint Amount) public
//     {
//         uint Range = Randomizers[_CurrentIndex].NumTokenIDs;
//         uint _CurrentDrawIndexTimes = CurrentDrawIndexTimes[ProjectID];
//         for(uint x; x < Amount; x++)
//         {
//             uint RandomID = uint(keccak256(abi.encodePacked(_CurrentDrawIndexTimes, Randomizers[_CurrentIndex].Randomness))) % Range;
//             if(!RandomizedTimeExists[ProjectID][RandomID])
//             {
//                 RandomizedTimes[ProjectID].push(RandomID * Randomizers[_CurrentIndex].IntervalInMilliseconds + Randomizers[_CurrentIndex].StartTime);
//                 RandomizedTimeExists[ProjectID][RandomID] = true;
//                 _CurrentDrawIndexTimes += 1;
//             }
//         }
//         CurrentDrawIndexTimes[ProjectID] = _CurrentDrawIndexTimes;
//     }

//     function ViewResults(uint ProjectID) public view returns ( uint[] memory, uint[] memory ) { return (RandomizedIDs[ProjectID], RandomizedTimes[ProjectID]); }
// }