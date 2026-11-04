# モバイル通信環境と一人当たりGDPの国際パネル分析

上智大学経済学部の卒業研究で、モバイル通信環境と一人当たりGDPの関係を調べました。GSMA Mobile Connectivity Indexと世界銀行のGDP関連指標を国・年で対応付け、通信網だけでなく端末保有や教育なども分析対象にしました。

**English summary.** An undergraduate economics project on mobile connectivity and GDP per capita. The public example uses synthetic data to demonstrate country and year fixed effects, one-year lags, and an interaction term.

## 担当と技術

| 項目 | 内容 |
| --- | --- |
| 担当 | 卒業研究として、通信環境の指標選定、国・年パネルの整形、モデル仕様の比較を実施 |
| 当時の実装 | R、`plm`、`openxlsx`、`dplyr`。国・年の固定効果、1期ラグ、対数変換、交互作用を含む仕様を試行 |
| このリポジトリ | 公開用に整理したRスクリプト。二方向固定効果を国・年のダミー変数で表し、1年ラグと交互作用を含む代表的な仕様を示す |

## 実行方法

R 4.4で動作を確認しました。外部パッケージは不要です。

```sh
Rscript --vanilla analyze.R --demo
Rscript --vanilla analyze.R panel.csv
```

`--demo` は固定シードで生成した架空のパネルを使います。出力には推定に使った観測数と、通信指標・端末指標・交互作用の係数を表示します。元研究の推定値は実データでの再計算と照合を経て掲載します。

## 実データを用意する場合

1. GSMA Mobile Connectivity Indexから利用条件に従って通信環境の指標を取得し、対象年の定義と単位を確認します。[GSMA MCI方法論（2024年版）](https://www.gsma.com/solutions-and-impact/connectivity-for-good/mobile-for-development/wp-content/uploads/2024/07/GSMA-MCI-Methodology-Report-2024.pdf)
2. 世界銀行から一人当たり実質GDPのPPP系列を取得し、国コードと年で通信指標に結合します。[World Bank WDI — NY.GDP.PCAP.PP.KD](https://data.worldbank.org/indicator/NY.GDP.PCAP.PP.KD)
3. CSVを `country,year,gdp_per_capita_ppp,network,ownership` の列で用意します。国・年は一意にし、`network` と `ownership` は定義と単位の揃った数値列にします。欠損は空欄か `NA` を使用します。ラグは前年の観測がある場合に作成します。

## 解釈上の限界

固定効果は、時間を通じて一定の国別要因と各年の共通変動を調整します。国ごとに変化する交絡やGDPから通信投資への逆方向の影響は残り得ます。推定値はモデル内の関連として扱います。このデモでは、配布版による指標改訂、欠測の扱い、元研究の標本選択を再現していません。
