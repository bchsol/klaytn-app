let pkey = "0x3327da0d0bf9af1cab4e8ef245d9fe62fdfef58a8828044bc4be5759f7390d37";
let addr = "0x150d78a12c015bde7e3319a3ab45fbb3cb3d40ca";

const CONTRACT = require("../build/contracts/TestNFT.json");

const Caver = require("caver-js");
const rpcURL = "https://api.baobab.klaytn.net:8651/";
const caver = new Caver(rpcURL);

const temp = caver.klay.accounts.createWithAccountKey(addr,pkey);
caver.klay.accounts.wallet.add(temp);
const acc = caver.klay.accounts.wallet.getAccount(0);

const networkID = "1001";
const deplyedNetworkAddress = CONTRACT.networks[networkID].address;
const contract = new caver.klay.Contract(CONTRACT.abi, deplyedNetworkAddress);

async function test() {
    let peb;
    let ret;

    peb = await caver.klay.getBalance(addr);
    console.log("before peb", peb);
    ret = await contract.methods.get_balance().call();
    console.log("get_balance", ret);

    ret = await contract.methods.mint(addr,1).send({
        from:addr,
        gas:"2000000",
    });

    ret = await contract.methods.tokenURL(1).call();
}
test();