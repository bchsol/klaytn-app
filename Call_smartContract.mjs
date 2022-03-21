import { createRequire } from "module";
const require = createRequire(import.meta.url);
const Contract = require("./build/contracts/TestNFT.json");

import Caver from "caver-js";
//import { MintKip17TokenRequest } from "caver-js-ext-kas/src/rest-client";
const rpcURL = "https://api.baobab.klaytn.net:8651/";
const networkID = "1001";
const caver = new Caver(rpcURL);

const addr = "";
const addrkey = "";

async function wait(ms) {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve();
    }, ms);
  });
}

async function test() {
  let ret;

  ret = caver.klay.accounts.createWithAccountKey(addr, addrkey);
  ret = caver.klay.accounts.wallet.add(ret);
  ret = caver.klay.accounts.wallet.getAccount(0);
  console.log("getAccount 0", ret.address);

  const deplyedNetworkAddress = Contract.networks[networkID].address;
  const contract = new caver.klay.Contract(Contract.abi, deplyedNetworkAddress);


  ret = await contract.methods.totalSupply().call();
  console.log("totalSupply", ret);

  ret = await contract.methods.mint(addr, 1).send({
    from:addr,
    gas: "8500000",
  });

  ret = await contract.methods.totalSupply().call();
  console.log("totalSupply", ret);


  ret = await caver.rpc.klay.getBalance(addr); // hex
  ret = caver.utils.hexToNumberString(ret); // number
  ret = caver.utils.convertFromPeb(ret, "KLAY"); // klay
  console.log("balance", ret);
}
test();