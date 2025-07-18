# [サービス名]
思い出ギフト

サブタイトル
〜誰かの定番が誰かの特別なギフトに〜

##  サービス概要
・自分のギフトの記録
・他ユーザーとの情報交換
・当日のお祝い忘れ防止

## 開発背景
誕生日や特別な日を大切にしています。相手のことを考えながらギフトを選ぶ時間が大好きで、自分のこと以上にこだわってしまうところがあります。
ギフトを用意してから渡すまでのワクワクする時間も大好きです。喜んでもらった時の記録を残したくて開発しました。
・同じギフトを贈らないように
・どんなギフトが喜ばれたのか記録
・洋服のサイズ等の記録

「60代 父の日」等ネットで調べればおすすめのプレゼントはたくさん出てくるが、結局毎年同じようなもの、PR商品などが検索で上がってきます。

毎年毎年名前入りのグラスやジョッキが出てきても正直ピンとこなかったです。

しかし職場で話していると自分では思いつかないようなギフトを贈っている人がいました。
これを投稿で見れるようにしたらギフトの幅も広がり、楽しいのではないかと考えました。
そして自分にとっては毎年贈っている商品でも、それが誰かにとっての初めての特別なギフトになるかもしれないと思いました。

## ターゲット層
20〜30代の層
20代…結婚祝いや出産祝いを初めて贈ることが多い年代
自分もそうだったがどんなものを贈ればいいか、実際に役に立つもの・喜ばれるものは何なのか分からないことだらけでした。

30代…祖父母・両親・甥姪など様々な世代にギフトを贈ることが多いため
特に義実家となると好みが分からず毎年同じようなものになってしまいます。

## ターゲット層の理由
20~30代の層 様々なライフイベントが増え、ギフトを贈る機会が多くなるため。

## ユーザー獲得方法
Xでの共有機能、ギフトを送るイベントの時期にSNSを使って宣伝していきます。

## サービス利用のイメージ
ギフトを贈るイベントが発生した際に、贈ったギフトを記録します。
「思い出ギフト」にいつ、誰に、何を贈ったかを記録しておく事で、次回ギフトを選ぶ際の参考になります。
相手の反応や好み、サイズ等も記録しておく事で、より喜んでもらえるギフトを選ぶことが出来ます。
また、自分の記録を公開する機能もあるため他の人が贈ったギフトを閲覧することも可能です。
たとえギフトに迷ってもこの機能を使うことで思いもよらないギフトを見つけることが出来ます。


## サービス差別化のポイント・推しポイント
- 類似サービス「TANP」「giftee」
ギフトをサイト内で購入し贈るサービスのため、サイト外で購入したギフトの記録が残せません。
「思い出ギフト」なら、ふらっと立ち寄ったお店で見つけた相手の喜びそうな商品や実物をみて店舗で買った商品の記録も残せます。ギフト相手ごとの記録を管理出来るため、いつ、何を贈ったかの情報が一目瞭然です。
- 類似サービス「Pinterest」
他の人のギフトアイディアの写真が閲覧出来るサービスのため、ギフト相手ごとの細かい記録が残せません。
「思い出ギフト」なら相手の反応や好み、サイズ等も記録出来、次回のギフトの参考になります。

## 機能候補
### MVP
- 認証系機能
  - ログインログアウト機能
  - 新規ユーザー登録機能

- ギフトメモ関連
  - ギフト記録の投稿（任意項目含む）
    - 日付／イベント／概要／費用/年代/ギフトアイテムのリンクなど
- 公開／非公開設定

- ギフトメモ一覧表示（公開分のみ）

### 本リリース
- 検索・整理
  - イベント名・年代・価格帯での検索
  - 検索機能のオートコンプリート

- 通知・シェア機能
  - 記念日リマインド（LINE Messaging API）
  - X（旧Twitter）へのシェア
  - OGPによる動的サムネイル生成

- ギフト相手管理
  - ギフト相手ごとの情報記録
    - 名前・年代・関係性・イベント・ギフトアイテム・費用・ギフトプロファイル機能（ギフト相手ごとの好みやNGリスト可視化）

- ギフトメモ関連
  - ギフト記事の投稿
    - 写真
    - アイテム名のオートコンプリート

## 拡張性
- ギフトメモのブックマーク機能
- コメント機能
- ギフト相手の画像
- 自分のアイコン

## 機能の実装方針予定
LINE Messaging API

## 技術スタック
- Railsのバージョン
7系

- 使用予定のデプロイサーバー
Render

- 使用予定のDB
Postgresql

- 使用予定のストレージサーバー
AWS s3 （拡張予定の機能で使用）

- 高度な技術で使う予定のGemやライブラリなど

LINE Messaging API

##画面遷移図
Figma：https://www.figma.com/design/sWr8c1NOlXmtgciSjGa4qQ/giftApp?node-id=0-1&p=f&t=eRLWYUXpuCbIHNnY-0

##ER図
[![Image from Gyazo](https://i.gyazo.com/ed80af959066191d2ab1de6c6ab95316.png)](https://gyazo.com/ed80af959066191d2ab1de6c6ab95316)
