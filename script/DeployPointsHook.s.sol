// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

import {PointsHook} from "../src/PointsHook.sol";
import {HookMiner} from "../test/utils/HookMiner.sol";

contract DeployPointsHook is Script {
    function setUp() public {}

    function run() public {
        // .env から各種値を取得
        address poolManager = vm.envAddress("POOL_MANAGER");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Hooks ライブラリの定義に従って、必要なフラグを計算
        uint160 flags = uint160(
            Hooks.AFTER_ADD_LIQUIDITY_FLAG | // 1 << 10 = 1024
            Hooks.AFTER_SWAP_FLAG           // 1 << 6  = 64
        ); // => 1024 | 64 = 1088 (0x0440)

        // constructor の引数は (IPoolManager, string, string)
        bytes memory constructorArgs = abi.encode(poolManager, "PointsToken", "PTS");

        // HookMiner を利用して、正しいフラグを持つアドレスになるよう salt を探索する
        (address hookAddress, bytes32 salt) =
            HookMiner.find(deployer, flags, type(PointsHook).creationCode, constructorArgs);

        // deployerPrivateKey を利用してデプロイ
        vm.broadcast(deployerPrivateKey);
        PointsHook pointsHook = new PointsHook{salt: salt}(
            IPoolManager(poolManager), "PointsToken", "PTS"
        );

        // マイニングしたアドレスと実際のデプロイ先アドレスが一致していることを確認
        require(address(pointsHook) == hookAddress, "DeployPointsHookScript: hook address mismatch");
        console.log("Deployed PointsHook at:", address(pointsHook));
    }
}
