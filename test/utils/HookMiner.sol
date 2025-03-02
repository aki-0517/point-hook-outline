// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title HookMiner
 * @notice ライブラリ: CREATE2 を利用したフックコントラクトのアドレスマイニングを行う
 *
 * 指定した deployer、creationCode、constructorArgs に基づき、
 * デプロイ先のアドレスの下位 8 ビットが desired flags と一致するような salt を探索します。
 */
library HookMiner {
    /**
     * @notice CREATE2 の salt を探索し、条件を満たすアドレスと salt を返す
     * @param deployer CREATE2 デプロイヤーのアドレス（実際の deployer アドレスを使用する）
     * @param flags 期待するフラグ（下位 8 ビットに現れるべき値）
     * @param creationCode デプロイするコントラクトの creation code
     * @param constructorArgs エンコード済みの constructor 引数
     * @return hookAddress 条件を満たすときの計算上のアドレス
     * @return salt salt 値
     */
    function find(
        address deployer,
        uint160 flags,
        bytes memory creationCode,
        bytes memory constructorArgs
    ) internal pure returns (address hookAddress, bytes32 salt) {
        // コントラクトの初期化コードハッシュを算出
        bytes32 initCodeHash = keccak256(abi.encodePacked(creationCode, constructorArgs));

        // 下位 8 ビットの期待値を求める
        uint8 expected = uint8(flags);

        // salt 値を 0 から順に探索する（十分な範囲で試行）
        for (uint256 i = 0; i < type(uint256).max; i++) {
            salt = bytes32(i);
            // CREATE2 によるデプロイ先アドレスを算出
            bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, initCodeHash));
            address computed = address(uint160(uint256(hash)));
            // computed の下位 8 ビットが expected と一致しているかチェック
            if (uint8(uint160(computed)) == expected) {
                return (computed, salt);
            }
        }
        revert("HookMiner: No valid salt found");
    }
}
