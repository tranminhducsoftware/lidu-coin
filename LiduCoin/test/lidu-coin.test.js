const LiduCoin = artifacts.require("LiduCoin");

const truffleAssert = require("truffle-assertions");
const web3Utils = require("web3-utils");

const { assert } = require("chai");
let contractInstance;
let ownerAddress;
const decimals = 6;

contract("LiduCoin", (accounts) => {
  console.log(accounts);

  it("should deploy LiduCoin Coin to Ganache Network", function () {
    return LiduCoin.deployed().then((instance) => {
      assert.isObject(instance);
    });
  });

  before(async () => {
    contractInstance = await LiduCoin.deployed();
    ownerAddress = accounts[0];
  });

  it("should owner is accounts[0]", async function () {
    const ownerAddress = await contractInstance.owner();
    assert.equal(ownerAddress, accounts[0]);
  });

  it("should mint when caller is owner", async function () {
    await contractInstance.mint(accounts[1], 2000);
    await contractInstance.mint(accounts[5], 2000);
    await contractInstance.mint(accounts[6], 2000);
    const balanceOfAccount1 = await contractInstance.getBalanceOf(accounts[1]);
    assert.equal(balanceOfAccount1, 2000 * 10 ** 6);
  });

  it("should error when not owner", async function () {
    let errMsg;
    try {
      await contractInstance.mint(accounts[2], 1000, {
        from: accounts[1],
      });
    } catch (e) {
      errMsg = e.message;
    }
    assert.match(errMsg, /Only owner can call/i);
  });

  it("should error Insufficient funds", async function () {
    let errMsg;
    try {
      await contractInstance.send(accounts[3], 100, {
        from: accounts[2],
      });
    } catch (e) {
      errMsg = e.message;
    }
    assert.match(errMsg, /Insufficient funds/i);
  });

  it("should send money correct", async function () {
    const receiver = accounts[3];
    const sender = accounts[1];
    const balanceOfSender = await contractInstance.getBalanceOf(sender);
    const transferAmount = 100 * Math.pow(10, decimals);
    const result = await contractInstance.send(receiver, 100, {
      from: sender,
    });
    truffleAssert.eventEmitted(result, "MoneySent", (ev) => {
      return (
        ev._sender === sender &&
        ev._receiver === receiver &&
        ev._amount_wei.toNumber() === transferAmount
      );
    });
    const balanceOfReceiver = await contractInstance.getBalanceOf(receiver);
    assert.equal(Number(balanceOfReceiver), transferAmount);

    const balanceOfSenderAfterTransfer = await contractInstance.getBalanceOf(
      sender
    );
    assert.equal(
      Number(balanceOfSender) - Number(transferAmount),
      Number(balanceOfSenderAfterTransfer)
    );
  });

  it("should error create loan request with amount less than 1", async function () {
    let errMsg;
    try {
      await contractInstance.createALoad(0, 1000, 10, 2, {
        from: accounts[1],
      });
    } catch (e) {
      errMsg = e.message;
    }
    assert.match(errMsg, /Amount is greater than 0/i);
  });

  it("should error create loan insufficient funds", async function () {
    let errMsg;
    try {
      await contractInstance.createALoad(1000, 1000, 10, 2, {
        from: accounts[3],
      });
    } catch (e) {
      errMsg = e.message;
    }
    assert.match(errMsg, /Insufficient funds/i);
  });

  it("should success create loan ", async function () {
    const sender =  accounts[6];
    const receiver =  accounts[1];
    const balanceOfSenderBefore = await contractInstance.getBalanceOf(sender);
    const balanceOfReceiverBefore = await contractInstance.getBalanceOf(receiver);
    console.log('balanceOfReceiverBefore',Number(balanceOfReceiverBefore));
    const tx = await contractInstance.createALoad(1000, 1000000, 10, 2, {
      from:sender,
    });

    truffleAssert.eventEmitted(tx, 'LoadCreated' ,(ev) => {
      return (
        Number(ev._id) === 0
      );
    });
    const balanceOfSenderAfter = await contractInstance.getBalanceOf(sender);
    const balanceOfReceiverAfter = await contractInstance.getBalanceOf(receiver);
    assert.equal(Number(balanceOfSenderBefore)-(1000* Math.pow(10, decimals)), Number(balanceOfSenderAfter));
    assert.equal(Number(balanceOfReceiverAfter)-(1000* Math.pow(10, decimals)), Number(balanceOfReceiverBefore));
  });
});
