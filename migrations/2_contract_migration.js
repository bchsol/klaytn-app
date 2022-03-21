var TestNFT = artifacts.require('TestNFT');

module.exports = function(deployer) {
  deployer.deploy(TestNFT).then(() => {
    if(TestNFT._json) {

    }
  });
};
