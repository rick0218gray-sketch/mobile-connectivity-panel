# モバイル通信環境と一人当たりGDPの国際パネル分析

上智大学経済学部の卒業研究で、モバイル通信環境と一人当たりGDPの関係を調べました。GSMA Mobile Connectivity Indexと世界銀行のGDP関連指標を国・年で対応付け、通信網だけでなく端末保有や教育なども分析対象にしました。

**English summary.** An undergraduate economics project on mobile connectivity and GDP per capita. The public example uses synthetic data to demonstrate country and year fixed effects, one-year lags, and an interaction term. The original GSMA and World Bank data are not redistributed here. Run the demo with `Rscript --vanilla analyze.R --demo` (base R only) and the checks with `Rscript --vanilla tests/test_analyze.R`.

> このリポジトリにあるのは、**手法を確認するための公開デモ**です。元の卒業研究のデータ・論文・推定結果は含みません。

## 元の研究と公開デモの違い

| 項目 | 元の卒業研究 | このリポジトリの公開デモ |
| --- | --- | --- |
| 担当 | 卒業研究として、通信環境の指標選定、国・年パネルの整形、モデル仕様の比較を実施 | 代表的な仕様を、公開用のRスクリプトに整理 |
| データ | GSMA Mobile Connectivity Indexと世界銀行の指標（公開対象外） | 固定シードで生成した架空のパネル（8か国・9年、ラグ作成後64観測） |
| 実装 | R、`plm`、`openxlsx`、`dplyr` | base Rのみ（`analyze.R`） |
| 推定 | 国・年の固定効果、1期ラグ、対数変換、交互作用を含む仕様を試行 | 国・年のダミー変数による二方向固定効果と、1年ラグ・交互作用を含む1仕様 |
| 結果の扱い | このREADMEには掲載していません | スクリプトの動作確認用。架空データのGDPは通信指標と無関係に生成しているため、係数に経済的な意味はありません |

## リポジトリの内容

| ファイル | 内容 |
| --- | --- |
| `analyze.R` | データの検証、1年ラグの作成、二方向固定効果モデルの推定を行うスクリプト（base Rのみ） |
| `tests/test_analyze.R` | `stopifnot` による動作確認（デモの観測数、国内でのラグ作成、既知の係数の再現、不正な入力での停止） |
| `.github/workflows/ci.yml` | GitHub Actionsで上記のデモとテストを実行する設定 |

## データについて

- 公開デモで使うデータは、`analyze.R` の中で固定シード（`set.seed(42)`）から生成する**架空のデータ**です。実在の国・年の値ではありません。
- 元の卒業研究で使ったGSMA Mobile Connectivity Indexと世界銀行のデータは、このリポジトリでは**再配布していません**。実データで実行する場合は、下の「実データを用意する場合」に従って各自で取得してください。
- `.gitignore` でCSV・Excelファイルを除外しているため、手元のデータが誤ってコミットされにくくなっています。

## モデル

国 $i$、年 $t$ について、次の二方向固定効果モデルを最小二乗法で推定します（国・年はダミー変数として入れます）。

$$
\ln(\mathit{GDPpc}_{it}) = \alpha_i + \gamma_t + \beta_1 N_{i,t-1} + \beta_2 O_{i,t-1} + \beta_3 \left(N_{i,t-1} \times O_{i,t-1}\right) + \varepsilon_{it}
$$

- $\mathit{GDPpc}_{it}$: 一人当たりGDP（PPP、列 `gdp_per_capita_ppp`）
- $N_{i,t-1}$: 通信網の指標の前年値（列 `network` から作成）
- $O_{i,t-1}$: 端末保有の指標の前年値（列 `ownership` から作成）
- $\alpha_i$: 国の固定効果、$\gamma_t$: 年の固定効果

ラグは同じ国の前年（`year - 1`）の観測と対応付けて作るため、行の並び順に依存せず、前年の観測がない場合は欠損になり推定から除かれます。出力は観測数と $\beta_1, \beta_2, \beta_3$ の点推定値のみで、標準誤差は表示しません。交互作用を含むため、$\beta_1$ は $O_{i,t-1} = 0$ のときの $N_{i,t-1}$ の係数（$\beta_2$ も同様）として読みます。

## 必要なもの

- R（下記のバージョンで確認）
- 追加パッケージは不要です。base Rに含まれる `stats`（`lm`）と `utils`（`read.csv`）だけを使います。

## 実行方法

R 4.4.2で動作を確認しました。R 4.3.3（Ubuntu 24.04の `r-base-core`）でも、以下のコマンドが成功することを確認しています。リポジトリのルートで実行します。

```sh
Rscript --vanilla analyze.R --demo          # 架空データでのデモ
Rscript --vanilla analyze.R panel.csv       # 手元で用意したパネルデータ
Rscript --vanilla tests/test_analyze.R      # 動作確認（成功時に "All checks passed." と表示）
```

`--demo` は固定シードで生成した架空のパネルを使います。出力には推定に使った観測数（デモでは64）と、通信指標・端末指標・交互作用の係数を表示します。列の不足、国・年の重複、非正のGDPはエラーで停止します。

GitHub Actions（`.github/workflows/ci.yml`）でも、`main` へのプッシュとプルリクエストのたびにデモとテストを実行します。

## 実データを用意する場合

1. GSMA Mobile Connectivity Indexから利用条件に従って通信環境の指標を取得し、対象年の定義と単位を確認します。[GSMA MCI方法論（2024年版）](https://www.gsma.com/solutions-and-impact/connectivity-for-good/mobile-for-development/wp-content/uploads/2024/07/GSMA-MCI-Methodology-Report-2024.pdf)
2. 世界銀行から一人当たり実質GDPのPPP系列を取得し、国コードと年で通信指標に結合します。[World Bank WDI — NY.GDP.PCAP.PP.KD](https://data.worldbank.org/indicator/NY.GDP.PCAP.PP.KD)
3. CSVを `country,year,gdp_per_capita_ppp,network,ownership` の列で用意します。国・年は一意にし、`network` と `ownership` は定義と単位の揃った数値列にします。欠損は空欄か `NA` を使用します。ラグは前年の観測がある場合に作成します。

## 解釈上の限界

固定効果は、時間を通じて一定の国別要因と各年の共通変動を調整します。国ごとに変化する交絡やGDPから通信投資への逆方向の影響は残り得ます。推定値はモデル内の関連として扱います。このデモでは、配布版による指標改訂、欠測の扱い、元研究の標本選択を再現していません。
