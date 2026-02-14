# Reader Review: 05_取引データモデル_UTXO

## Length Check
- target: `8500`
- range: `7650 - 9350`
- count(no-whitespace): `7656`
- delta: `-844`
- status: `PASS`

## Confusion points
1. 章後半で「モデル説明」「運用監視」「通知設計」が密に並ぶため、初学者には層の切替が速く感じる可能性がある。

## Why it breaks the mental model
- 中心主張は明確だが、終盤で実装・運用・サポートの話題が連続すると、読者がどの層の要件を読んでいるかを見失いやすい。

## Rewrite suggestion
- 補助ケース冒頭に「ここから運用層」と明示し、05-1〜05-4の理論主線との境界を1文で示す。

## Questions to verify
- 追加の要検証事項はなし。

## Human-likeness check
- H1: PASS（章内接続は自然）
- H2: PASS（抽象語の参照先は維持）
- H3: PASS（情報量は多いが段落分割済み）
- H4: PASS（文型の偏りは小さい）
- H5: PASS（重複主張は圧縮済み）
