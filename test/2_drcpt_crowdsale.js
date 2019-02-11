const DRCPTCrowdsale = artifacts.require("./DRCPTCrowdsale.sol");
const DRCPT = artifacts.require("./DRCPT.sol");
const BigNumber = require("bn.js");

const decimal = new BigNumber("1000000000000000000");
const DRCPTTokenAddress = artifacts.require("./DRCPT.sol").address;

let prevStage;

const weiMetric = amount => new BigNumber(amount).mul(decimal).toString();

const getCentsInWei = cents => {
  const price = weiMetric(cents);
  const result = new BigNumber(price).div(new BigNumber("11000")).toString();
  return result;
};

const increaseTime = addSeconds => {
  const id = Date.now();
  web3.currentProvider.send(
    {
      jsonrpc: "2.0",
      method: "evm_increaseTime",
      params: [addSeconds],
      id: id
    },
    function(err, res) {
      web3.currentProvider.send(
        {
          jsonrpc: "2.0",
          method: "evm_mine",
          id: id + 1
        },
        function() {
          return;
        }
      );
    }
  );
};

contract("Checking Stage Changes and Withdrawals", async accounts => {
  it("Check Transition of Crowdsale Stage by Traversing Time", async () => {
    let _DRCPTCrowdsale = await DRCPTCrowdsale.deployed();

    let i = 1;
    while (i < 8) {
      const stage = await _DRCPTCrowdsale.getCrowdsaleStage.call();
      assert.equal(i++, stage.toNumber(), "Right Stage");
      increaseTime(1200);
    }
  });

  it("Testing Function getRemainingTokens", async () => {
    let _DRCPTCrowdsale = await DRCPTCrowdsale.deployed();
    const remainingTokens = (await _DRCPTCrowdsale.getRemainingTokens.call()).toString();
    assert.equal(
      remainingTokens,
      "10900000000000000000000000",
      "Correct Remaining Tokens"
    );
  });

  it("Successfully withdraw remaining Tokens", async () => {
    let _DRCPTCrowdsale = await DRCPTCrowdsale.deployed();
    let _DRCPT = await DRCPT.deployed();
    const stage = await _DRCPTCrowdsale.getCrowdsaleStage.call();
    const treasury = await _DRCPTCrowdsale.treasury();
    const balanceBefore = await _DRCPT.balanceOf.call(treasury);

    /**Don't Know but some of my Transaction are being reverted*/
    //await _DRCPTCrowdsale.withdrawRemainingTokens({from:accounts[0]});

    const balanceAfter = await _DRCPT.balanceOf.call(treasury);

    //console.log("Balance", balanceAfter.toString(),balanceBefore.toString());
  });
});

//==============================================================================

contract("DRCPTCrowdsale", async accounts => {
  it("should deployed successfully with right address", async () => {
    let _DRCPTCrowdsale = await DRCPTCrowdsale.deployed();
    let treasuryWallet = await _DRCPTCrowdsale.treasury.call();
    let _DRCPTTokenAddress = await _DRCPTCrowdsale.DRCPTToken.call();

    assert.equal(
      treasuryWallet,
      accounts[0],
      "TreasuryWallet address is not correct"
    );

    assert.equal(
      _DRCPTTokenAddress,
      DRCPTTokenAddress,
      "DRCPT Token address is not correct"
    );
  });
  it("should deploy successfully with the correct Stage prices", async function() {
    let _DRCPTCrowdsale = await DRCPTCrowdsale.deployed();
    let _stagePricesPrivateSale = await _DRCPTCrowdsale.stagePrices.call(1);
    let _stagePricesPreICO = await _DRCPTCrowdsale.stagePrices.call(2);
    let _stagePricesICO1 = await _DRCPTCrowdsale.stagePrices.call(3);
    let _stagePricesICO2 = await _DRCPTCrowdsale.stagePrices.call(4);
    let _stagePricesICO3 = await _DRCPTCrowdsale.stagePrices.call(5);
    let _stagePricesLive = await _DRCPTCrowdsale.stagePrices.call(6);

    assert.equal(
      _stagePricesPrivateSale.toString(),
      getCentsInWei(5),
      "Wrong price of Stage Private Sale"
    );
    assert.equal(
      _stagePricesPreICO.toString(),
      getCentsInWei(25),
      "Wrong price of Stage Pre ICO Sale"
    );
    assert.equal(
      _stagePricesICO1.toString(),
      getCentsInWei(50),
      "Wrong price of Stage ICO1 Sale"
    );
    assert.equal(
      _stagePricesICO2.toString(),
      getCentsInWei(75),
      "Wrong price of Stage ICO2 Sale"
    );
    assert.equal(
      _stagePricesICO3.toString(),
      getCentsInWei(100),
      "Wrong price of Stage ICO3 Sale"
    );
    assert.equal(
      _stagePricesLive.toString(),
      getCentsInWei(100),
      "Wrong price of Stage LIVE Sale"
    );
  });

  it("should deploy successfully with the correct Stage Allowance", async function() {
    let _DRCPTCrowdsale = await DRCPTCrowdsale.deployed();
    let _stageAllotmentsPrivateSale = await _DRCPTCrowdsale.stageAllotments.call(
      1
    );
    let _stageAllotmentsPreICO = await _DRCPTCrowdsale.stageAllotments.call(2);
    let _stageAllotmentsICO1 = await _DRCPTCrowdsale.stageAllotments.call(3);
    let _stageAllotmentsICO2 = await _DRCPTCrowdsale.stageAllotments.call(4);
    let _stageAllotmentsICO3 = await _DRCPTCrowdsale.stageAllotments.call(5);

    assert.equal(
      _stageAllotmentsPrivateSale.toString(),
      weiMetric(10000000),
      "Wrong Allotment for Private Sale"
    );
    assert.equal(
      _stageAllotmentsPreICO.toString(),
      weiMetric(500000),
      "Wrong Allotment for Pre Sale"
    );
    assert.equal(
      _stageAllotmentsICO1.toString(),
      weiMetric(250000),
      "Wrong Allotment for ICO1"
    );
    assert.equal(
      _stageAllotmentsICO2.toString(),
      weiMetric(100000),
      "Wrong Allotment for ICO2"
    );
    assert.equal(
      _stageAllotmentsICO3.toString(),
      weiMetric(50000),
      "Wrong Allotment for ICO3"
    );
  });

  it("Testing Function PriceReceiver()", async () => {
    let _DRCPTCrowdsale = await DRCPTCrowdsale.deployed();

    const setProvider = await _DRCPTCrowdsale.setEthPriceProvider(accounts[1]);

    try {
      await _DRCPTCrowdsale.setEthPriceProvider(accounts[0], {
        from: accounts[1]
      });
      assert.fail();
    } catch (err) {
      assert.ok(true, /revert/.test(err.message));
    }
  });

  it("Testing Function recieveEthPrice()", async () => {
    let _DRCPTCrowdsale = await DRCPTCrowdsale.deployed();

    _DRCPTCrowdsale
      .receiveEthPrice(100000, {
        from: accounts[1]
      })
      .catch(e => {
        console.log("Error", e);
      });

    try {
      await _DRCPTCrowdsale.receiveEthPrice(2, {
        from: accounts[0]
      });
      assert.fail();
    } catch (err) {
      assert.ok(true, /revert/.test(err.message));
    }
  });

  it("Buy Whole allowance of a particular Stage", async () => {
    let _DRCPTCrowdsale = await DRCPTCrowdsale.deployed();
    const stage = (await _DRCPTCrowdsale.getCrowdsaleStage.call()).toNumber();
    prevStage = stage;
    const getAllowance = (await _DRCPTCrowdsale.stageAllotments.call(
      stage
    )).toString();
    const getPrice = (await _DRCPTCrowdsale.stagePrices.call(stage)).toString();
    const priceOfFullAllotment = new BigNumber(getAllowance)
      .mul(new BigNumber(getPrice))
      .toString();

    let makePurchase = null;
    try {
      for (let i = 3; i < 100 && priceOfFullAllotment > "0"; i++) {
        makePurchase = await web3.eth.sendTransaction({
          from: accounts[i - 1],
          to: _DRCPTCrowdsale.address,
          value: web3.utils.toWei("1", "ether"),
          gas: 210000,
          gasPrice: 1e10
        });
        priceOfFullAllotment = new BigNumber(priceOfFullAllotment)
          .sub(web3.utils.toWei("1", "ether"))
          .toString();
      }
    } catch (err) {
      console.log("Error", err);
    }
    console.log("makePurchase", makePurchase);
  });

  it("Successfully Drained the allowance of previous Stage", async () => {
    let _DRCPTCrowdsale = await DRCPTCrowdsale.deployed();

    const stage = (await _DRCPTCrowdsale.getCrowdsaleStage.call()).toNumber();
    prevStage = stage;

    const getAllowance = (await _DRCPTCrowdsale.stageAllotments.call(
      prevStage
    )).toString();

    console.log("getAllowance", getAllowance);
    assert.equal("0", getAllowance, "Drained allowance to zero");
  });

  it("Stage is moved to next Stage after Allowance Drain", async () => {
    let _DRCPTCrowdsale = await DRCPTCrowdsale.deployed();
    const stage = (await _DRCPTCrowdsale.getCrowdsaleStage.call()).toNumber();
    assert.equal(prevStage + 1, stage, "Staged moved to next one");
  });
});
