import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, Signer } from 'ethers';

describe('Mover', function () {
  let mover: Contract, nft: Contract;
  let alice: Signer, bob: Signer;
  it("test passing", async () => {
        expect(2).eq(2);
        const m = await ethers.getContractFactory('OracleFactory');
        const oracle = await m.deploy();
        await oracle.deployed();
        const dkgAddr = await oracle.startNewOracle();
        expect(dkgAddr).to.not.be.eq("0")
  });
})
