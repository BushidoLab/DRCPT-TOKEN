pragma solidity >= 0.4.21 < 0.6.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Ownable.sol";

contract PriceReceiver {
    address public ethPriceProvider;

    modifier onlyEthPriceProvider() {
        require(msg.sender == ethPriceProvider);
        _;
    }

    // constructor(address _ethPriceProvider) internal{
    //     ethPriceProvider = _ethPriceProvider;
    // }

    function receiveEthPrice(uint ethUsdPrice) external;

    function setEthPriceProvider(address provider) external;
}

contract DRCPTCrowdsale is PriceReceiver, Ownable {
    using SafeMath for uint256;

    uint256 public constant PRIVATE_SALE = 1;
    uint256 public constant PRE_ICO = 2;
    uint256 public constant ICO_1 = 3;
    uint256 public constant ICO_2 = 4;
    uint256 public constant ICO_3 = 5;
    uint256 public constant LIVE = 6;
    uint256 public constant DONE = 7;

    uint256 public privateSaleEnd;
    uint256 public preICOEnd;
    uint256 public ico1End;
    uint256 public ico2End;
    uint256 public ico3End;
    uint256 public liveEnd;

    ERC20 public DRCPTToken;
    address payable public treasury;

    uint256 public ethPrice;
    uint256 public dollarInWei;
    uint256 public currentStage;
    uint256 public currentETHPrice;
    uint256 public treasuryWalletAllotment;

    mapping(address => uint256) public contributions;
    mapping(address => uint256) public purchasedAmounts;
    // stagePrices is the amount of ETH needed for one token.
    mapping(uint256 => uint256) public stagePrices;
    mapping(uint256 => uint256) public stageAllotments;
    mapping(uint256 => uint256) public totalWeiRaisedAtStage;

    // Events
    event TokensSold(address indexed buyer, uint256 indexed tokenAmount, uint256 atStage);

    modifier validAddress(address _address){
        require(_address != address(0x0), "Address is 0");
        _;
    }

    modifier tokenSaleActive() {
        require(now <= ico3End, "ICO has ended.");
        _;
    }

    modifier tokenSaleOver() {
        require(now >= ico3End, "ICO is still going.");
        _;
    }

    // Constructor
    // ============
    constructor (
        address payable _treasury,
        uint256[6] memory timestamps,
        address _tokenAddress
        //address _ethPriceProvider
    )
        public
        validAddress(_treasury)
        validAddress(_tokenAddress)
     //  validAddress(_ethPriceProvider)
        Ownable()
     //   PriceReceiver(_ethPriceProvider)
    {
        ethPrice = 11000;
        treasury = _treasury;
        DRCPTToken = ERC20(_tokenAddress);

        stagePrices[PRIVATE_SALE] = getCentsInWei(5);
        stagePrices[PRE_ICO] = getCentsInWei(25);
        stagePrices[ICO_1] = getCentsInWei(50);
        stagePrices[ICO_2] = getCentsInWei(75);
        stagePrices[ICO_3] = getCentsInWei(100);
        stagePrices[LIVE] = getCentsInWei(100);

        privateSaleEnd = timestamps[0];
        preICOEnd = timestamps[1];
        ico1End = timestamps[2];
        ico2End = timestamps[3];
        ico3End = timestamps[4];
        liveEnd = timestamps[5];

        stageAllotments[PRIVATE_SALE] = 10000000 * 10**18;
        stageAllotments[PRE_ICO] = 500000 * 10**18;
        stageAllotments[ICO_1] = 250000 * 10**18;
        stageAllotments[ICO_2] = 100000 * 10**18;
        stageAllotments[ICO_3] = 50000 * 10**18;
        stageAllotments[LIVE] = 1; // To avoid skiping of this stage
    }

    function receiveEthPrice(uint ethUsdPrice) external onlyEthPriceProvider {
        require(ethUsdPrice > 0);
        ethPrice = ethUsdPrice;
        updatePrices();
    }

    function setEthPriceProvider(address provider) external validAddress(provider) onlyOwner {
        ethPriceProvider = provider;
    }

    // Token Purchase
    // =========================
    function () external payable {
        buyTokens(msg.value);
    }

    function updatePrices() public onlyOwner {
        stagePrices[PRIVATE_SALE] = getCentsInWei(5);
        stagePrices[PRE_ICO] = getCentsInWei(25);
        stagePrices[ICO_1] = getCentsInWei(50);
        stagePrices[ICO_2] = getCentsInWei(75);
        stagePrices[ICO_3] = getCentsInWei(100);
        stagePrices[LIVE] = getCentsInWei(100);
    }

    // TODO needs onlyOwner
    function withdrawRaisedETH() public tokenSaleOver onlyOwner {
        uint256 total = 0;
        for (uint256 stage = PRIVATE_SALE; stage < LIVE; stage++) {
            uint256 weiRaised = totalWeiRaisedAtStage[stage];
            if (weiRaised != 0) {
                totalWeiRaisedAtStage[stage] = 0;
                total = total.add(weiRaised);
            }
        }
        treasury.transfer(total);
    }

    // TODO needs onlyOwner
    function withdrawRemainingTokens() public tokenSaleOver onlyOwner {
        uint256 total = 0;
        for (uint256 stage = PRIVATE_SALE; stage < LIVE; stage++) {
            uint256 allotment = stageAllotments[stage];
            if (allotment != 0) {
                stageAllotments[stage] = 0;
                total = total.add(allotment);
            }
        }
        DRCPTToken.transfer(treasury, total);
    }

    function getRemainingTokens() public view returns (uint256) {
        uint256 tokens = 0;
        for (uint256 stage = PRIVATE_SALE; stage < LIVE; stage++) {
            tokens = tokens.add(stageAllotments[stage]);
        }
        return tokens;
    }

    // TODO - add check for owner withdrawal
    function getRefund() public tokenSaleOver {
        uint256 contribution = contributions[msg.sender];
        uint256 purchasedAmount = purchasedAmounts[msg.sender];
        require(contribution > 0, "You didn't participate in the crowdsale");
        require(purchasedAmount > 0, "You didn't participate in the crowdsale");
        contributions[msg.sender] = 0;
        purchasedAmounts[msg.sender] = 0;
        msg.sender.transfer(contribution);
        DRCPTToken.transferFrom(msg.sender, address(this), purchasedAmount);
    }

    // Get Crowdsale stage.
    function getCrowdsaleStage() public view returns (uint256) {
        uint256 stage = 7; // Becasue after LIVE, It was returning stage 1 which is wrong.
        if (now < privateSaleEnd) {
            stage = PRIVATE_SALE;
        } else if (now < preICOEnd) {
            stage = PRE_ICO;
        } else if (now < ico1End) {
            stage = ICO_1;
        } else if (now < ico2End) {
            stage = ICO_2;
        } else if (now < ico3End) {
            stage = ICO_3;
        } else if (now < liveEnd) {
            stage = LIVE;
        }

        while (stageAllotments[stage] == 0 && stage < LIVE) {
            stage++;
        }

        return stage;
    }

    function withdrawToken(address token) external onlyOwner validAddress(token) {
        require(token != address(DRCPTToken));
        ERC20 erc20 = ERC20(token);
        erc20.transfer(msg.sender, erc20.balanceOf(address(this)));
    }

    //buyTokens
    //=============================================================
    function buyTokens(uint256 ethSent) internal tokenSaleActive {
        uint256 stage = getCrowdsaleStage();
        if(currentStage != stage) {
            currentStage = stage;
        }
        require(ethSent >= stagePrices[stage], "Not enough ETH sent");
        uint256 tokens = ethSent.div(stagePrices[stage]);
        // Check here to make sure we don't go over an allotment
        if (tokens > stageAllotments[stage]) {
            tokens = stageAllotments[stage];
            // Calculate how much ETH we use to fill the rest of the allotment.
            uint256 ethUsed = ethSent.mul(tokens).div(stageAllotments[stage]);
            executePurchase(tokens, ethUsed);
            // Refund the ETH that is out of the crowdsale amount
            msg.sender.transfer(ethSent.sub(ethUsed));
        } else {
            executePurchase(tokens, ethSent);
        }
    }

    function executePurchase(uint256 tokens, uint256 eth) internal {
        uint256 stage = currentStage;
        contributions[msg.sender] = contributions[msg.sender].add(eth);
        purchasedAmounts[msg.sender] = purchasedAmounts[msg.sender].add(tokens);
        totalWeiRaisedAtStage[stage] = totalWeiRaisedAtStage[stage].add(eth);
        stageAllotments[stage] = stageAllotments[stage].sub(tokens);
        DRCPTToken.transfer(msg.sender, tokens);
        emit TokensSold(msg.sender, tokens, stage);
    }

    function getCentsInWei(uint256 cents) internal view returns (uint256) {
        return uint256(1 ether).mul(cents).div(ethPrice);
    }

    function getTimeNow()external view returns (uint256) {
        return now;
    }
}
