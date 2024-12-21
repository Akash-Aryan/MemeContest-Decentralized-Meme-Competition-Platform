// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MemeContest {
    address public owner;
    uint256 public contestEndTime;
    uint256 public totalVotes;
    uint256 public rewardPool;

    struct Meme {
        uint256 id;
        address creator;
        string uri; // URI to the meme image or video
        uint256 votes;
    }

    mapping(uint256 => Meme) public memes;
    mapping(address => bool) public voters;
    uint256 public memeCount;

    event MemeSubmitted(uint256 memeId, address creator, string uri);
    event Voted(address voter, uint256 memeId);
    event RewardDistributed(address creator, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier contestOngoing() {
        require(block.timestamp < contestEndTime, "Contest has ended");
        _;
    }

    modifier contestEnded() {
        require(block.timestamp >= contestEndTime, "Contest is still ongoing");
        _;
    }

    constructor(uint256 _duration, uint256 _rewardPool) {
        owner = msg.sender;
        contestEndTime = block.timestamp + _duration;
        rewardPool = _rewardPool;
    }

    function submitMeme(string memory uri) public contestOngoing {
        memeCount++;
        memes[memeCount] = Meme(memeCount, msg.sender, uri, 0);
        emit MemeSubmitted(memeCount, msg.sender, uri);
    }

    function voteForMeme(uint256 memeId) public contestOngoing {
        require(!voters[msg.sender], "You have already voted");
        require(memeId > 0 && memeId <= memeCount, "Invalid meme ID");

        memes[memeId].votes++;
        voters[msg.sender] = true;
        totalVotes++;

        emit Voted(msg.sender, memeId);
    }

    function distributeRewards() public contestEnded onlyOwner {
        uint256 totalVotesForReward = totalVotes;
        for (uint256 i = 1; i <= memeCount; i++) {
            uint256 reward = (memes[i].votes * rewardPool) / totalVotesForReward;
            payable(memes[i].creator).transfer(reward);
            emit RewardDistributed(memes[i].creator, reward);
        }
    }

    function getMeme(uint256 memeId) public view returns (string memory, uint256) {
        require(memeId > 0 && memeId <= memeCount, "Invalid meme ID");
        Meme memory meme = memes[memeId];
        return (meme.uri, meme.votes);
    }

    function getContestStatus() public view returns (string memory) {
        if (block.timestamp < contestEndTime) {
            return "Contest is ongoing";
        } else {
            return "Contest has ended";
        }
    }

    // Withdraw the contract balance to the owner if necessary
    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // Receive ETH to fund the reward pool
    receive() external payable {}
}
