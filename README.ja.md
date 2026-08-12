# vive-ultimate-tracker-poweroff

![Platform: Windows](https://img.shields.io/badge/platform-Windows-0078D6)
![AutoHotkey v2](https://img.shields.io/badge/AutoHotkey-v2-334455)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

[English](README.md)

ファイルをひとつ実行するだけで、**VIVE Ultimate Tracker の電源をまとめてオフ**にできます。

VIVE Hub には外部から呼べる公式 API・コマンドラインがないため、本ツールは
AutoHotkey v2 スクリプトが UI オートメーションで VIVE Hub を自動操作し、
電源オフボタンを代わりにクリックします。Stream Deck のボタンに割り当てれば、
ワンプッシュの「トラッカー全オフ」スイッチになります。

## 動作の仕組み

スクリプトを実行すると、VIVE Hub の画面状態によらず以下を全自動で行います。

1. VIVE Hub のウィンドウを探す。**VIVE Hub が起動していなければ、
   トラッカーも接続されていないはずなので、通知だけ出して何もせず終了**
2. 設定ウィンドウが開いていなければ、**歯車メニューの「設定」を自動で呼び出して開く**
3. 「VIVE トラッカー (Ultimate)」タブを選択
4. 「すべてオフにする」をクリック
   - ボタンが無効（＝接続中のトラッカーが 0 台）なら
     「すでにすべてオフ」と通知して正常終了
5. **確認ダイアログの「オフにする」を自動でクリック**
6. 「現在トラッキング中」が 0 台になったのを確認して通知
7. スクリプトが自分で開いた設定ウィンドウは閉じて元の状態に戻す

ボタン類は座標ではなく AutomationId（`oetTurnOffAllBtn` など）で特定しているため、
ウィンドウの位置・サイズ・DPI に影響されません（VIVE Hub 2.5.6 で確認済み）。
VIVE Hub の UI は日本語・英語のどちらにも対応しています。

## 動作環境

- Windows
- [VIVE Hub](https://www.vive.com/)（VIVE Ultimate Tracker がセットアップ済みであること。
  VIVE Hub 2.5.6 で確認済み）
- [AutoHotkey](https://www.autohotkey.com/) **v2** … スクリプト版を使う場合のみ。
  ビルド済み exe 版なら AutoHotkey のインストールは不要です

## セットアップ

### 方法 A: ビルド済み exe（かんたん）

1. [Releases](https://github.com/kxn4t/vive-ultimate-tracker-poweroff/releases)
   から最新の `vive-ultimate-tracker-poweroff-vX.Y.Z.zip` をダウンロードする
2. 展開して、フォルダーごと好きな場所に配置する

> [!NOTE]
> コンパイル済みの AutoHotkey 実行ファイルは、アンチウイルスソフトや
> SmartScreen に誤検知されることがあります。ソースコードはこのリポジトリで
> すべて公開しているので、気になる場合は下のスクリプト版を使ってください。

### 方法 B: スクリプトを直接実行する

1. https://www.autohotkey.com/ から AutoHotkey **v2** をインストールする
   （v1 では動きません）
2. このリポジトリをダウンロードして（Code → Download ZIP して展開、
   または `git clone`）、フォルダーごと好きな場所に配置する。`UIA.ahk` は
   `PowerOffViveTrackers.ahk` と同じフォルダーに置いたままにしてください

## 使い方

トラッカーの電源が入った状態で `PowerOffViveTrackers.exe`
（スクリプト版なら `PowerOffViveTrackers.ahk`）をダブルクリックします。
確認ダイアログまで自動で進み、トラッカーがオフになれば成功です。

### オプション: タスクバーにピン留めする

- **exe 版**: `PowerOffViveTrackers.exe` を右クリック →「タスクバーにピン留めする」
  （Windows 11 では「その他のオプションを確認」の中にあります）
- **スクリプト版**: .ahk ファイルは直接ピン留めできないため、リンク先を
  `"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "C:\Tools\vive-ultimate-tracker-poweroff\PowerOffViveTrackers.ahk"`
  にしたショートカットを作り、そのショートカットをピン留めしてください

### オプション: Stream Deck に割り当てる

1. Stream Deck アプリでボタンに **「システム」→「開く」** アクションをドラッグ
2. 「App/ファイル」に `PowerOffViveTrackers.exe` のフルパスを指定
   （スクリプト版なら .ahk のパスを指定。.ahk の関連付けがうまく動かない場合は、
   上のタスクバーの節と同じように AutoHotkey64.exe 経由で指定）
3. お好みでアイコンとタイトルを設定して完成

## うまく動かないとき（dump モード）

VIVE Hub のアップデートで UI の AutomationId や文言が変わると、
要素が見つからなくなることがあります。その場合は次の手順で調整してください。

1. コマンドプロンプトなどから引数 `dump` を付けて実行する:
   ```
   PowerOffViveTrackers.exe dump
   ```
   （スクリプト版:
   `"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "C:\Tools\vive-ultimate-tracker-poweroff\PowerOffViveTrackers.ahk" dump`）
2. メモ帳で `vivehub_elements.txt` が開くので、対象ボタンの
   `AutomationId:` や `Name:` を探す（Ctrl+F で「オフ」を検索すると早いです）
3. スクリプト冒頭の「Settings」セクションの該当 ID / 正規表現を書き換えて、
   スクリプト版で実行する。exe 版を使っている場合は、修正版をリリースできるよう
   Issue で知らせてもらえると助かります

※ dump は VIVE Hub の全ウィンドウ（メイン＋設定）を出力します。
設定ウィンドウ側を調べたいときは、設定画面を開いた状態で実行してください。

## 設定項目

設定はすべてスクリプト冒頭にまとまっています。

- `ID_*` … 各 UI 要素の AutomationId（VIVE Hub 2.5.6 で確認済み）
- `*_REGEX` … 名前ベースのフォールバック用正規表現（日本語・英語 UI 両対応）
- `*_TIMEOUT` … 各ステップの待ち時間

## 注意

- UI の自動操作なので、VIVE Hub のアップデートで UI が変わると
  調整が必要になることがあります（dump モードで再確認）
- 実行中、VIVE Hub のウィンドウが一瞬前面に出ます
- トラッカーが 1 台も接続されていないときは「すべてオフにする」ボタン自体が
  無効になっているため、その場合は何もせず通知だけ出して終了します
- 通知・エラーメッセージは、日本語 OS では日本語、それ以外では英語で表示されます

## ライセンス

MIT License — [LICENSE](LICENSE) を参照してください。

同梱の `UIA.ahk` はサードパーティー製ライブラリ
（[Descolada/UIA-v2](https://github.com/Descolada/UIA-v2)）であり、
別途 MIT License で提供されています。[LICENSE-UIA](LICENSE-UIA) を
参照してください。

Releases ページのビルド済み exe には、さらに AutoHotkey v2 ランタイム
（GNU General Public License v2）が埋め込まれています。
[LICENSE-AutoHotkey](LICENSE-AutoHotkey) を参照してください。
