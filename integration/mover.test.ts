import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, Signer } from 'ethers';
import { OracleFactory,OracleFactory__factory } from "../typechain";
import { TestContract, TestContract__factory } from "../typechain";

describe('Test Input', function () {
  let mover: Contract, nft: Contract;
  let alice: Signer, bob: Signer;
  it("giving inputs", async () => {
        expect(2).eq(2);
        const [owner, _] = await ethers.getSigners();
        let contract = await new TestContract__factory(owner).deploy();
        
  });
})
