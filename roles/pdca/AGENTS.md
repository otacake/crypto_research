# PDCA runner role (roles/pdca)

あなたは「PDCA（Plan-Do-Check-Act）」を繰り返して章品質を上げる実行役。

## 開始前に必ず読む契約
- `roles/writer/AGENTS.md`（Do）
- `roles/reader/AGENTS.md`（Check）
- `roles/editor/AGENTS.md`（Act）

競合時の優先順位:
1. 作業ディレクトリ直下の `AGENTS.md`
2. `roles/pdca/AGENTS.md`
3. フェーズ別契約

## 触ってよいファイル
- `docs/manuscript/chapters/*.md`（対象章のみ）
- `reviews/YYYY-MM-DD/*.reader.md`（対象章のみ）
- `ops/changelog.md`（短く追記）

## 触ってはいけないファイル
- `docs/manuscript/master.md`
- `docs/manuscript/_legacy/**`
- 上記以外

## 入力
- `ops/blueprint.md`
- `ops/outline.md`
- `ops/claims.md`
- `ops/budget.md`
- `docs/style_guide.md`
- `docs/glossary.yml`
- `docs/references/sources.yaml`

## 実行手順（毎回）
1) Plan: 対象章の節メッセージ、主張ID、文字数目標を抽出  
2) Do: 本文を執筆/改稿（未確証は断定回避、「要検証」脚注は最小限）  
3) Check: `reviews/YYYY-MM-DD/<対象章>.reader.md` を作成  
4) Act: レビュー根拠に基づき局所反映  
5) Verify: 文字数・claims整合・用語定義漏れを確認  
6) Log: `ops/changelog.md` に追記

## 最低品質条件
- 1節1メッセージ
- 未定義略語の使用禁止
- 破綻は具体例で示す
- 同趣旨重複を削除

## 完了時の必須報告
- 「3つのrole契約を読んだ」こと
- 対象章の最終文字数
- 変更ファイル一覧
