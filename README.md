# 抹茶と神社。

<img src="https://user-images.githubusercontent.com/94298144/189052247-e5390c19-8701-49c7-83ec-3e9793c8d363.png" width="400" height="400">
サービスURL: https://greentea-temple.herokuapp.com/

# ■ サービス概要
　京都にある抹茶スイーツのお店の近くにある神社仏閣を調べたり、  
　京都にある神社仏閣近くの抹茶スイーツを調べたりすることができ、  
　現在地近くにある抹茶スイーツ店と神社仏閣を調べることができ、  
　また自分だけの抹茶スイーツと神社仏閣のモデルルートが作成出来るサービスです。  

# ■メインのターゲットユーザー
　・京都観光に来る人  
　・抹茶スイーツと神社仏閣巡りが好きな人  
　・どちらかに行く予定がある、興味がある人 

# ■ユーザーが抱える課題
　折角京都に観光に来るなら、   
　京都で有名な抹茶スイーツを食べ、神社仏閣を同時に巡りたいと考えるユーザーは多いと考えられる。  
　しかし抹茶スイーツをまとめたサイトや、神社仏閣をまとめたサイトはあっても、  
　それら二つを同時に見られるサイトはあまりない。  
　その為それら二つを同時に探すことができ、  
　尚且つ行きたい箇所の距離や行き方を調べたりすることができるようにしたい。  

# ■解決方法  
　・興味のあるスイーツのジャンルから抹茶スイーツを探すことができる  
　・行く予定のある地域の神社仏閣を調べることができる  
　・行きたい抹茶スイーツ店近くの神社仏閣、行きたい神社仏閣近くの抹茶スイーツ店を知ることができる  
　・現在地から行ける抹茶スイーツ店、神社仏閣を調べることができる  
　・行きたい箇所、もしくは知っているおすすめの場所のモデルルートを作成することができる    　

# ■サービス作成の背景
　自分自身が抹茶スイーツ店と神社仏閣を巡るのが好きだが、どちらの情報も揃ったサービスはなかった  
　折角京都に来たのなら、どちらも巡りたいと考える人は多いと考えられる。  
　またこれを機に抹茶スイーツのお店や神社仏閣をもっと手軽に知って、スムーズに観光できるようにして欲しい  

# ■機能に関して  

　・抹茶スイーツのカテゴリから検索できる機能  
　(パフェ、ティラミス、ドリンクなど……)  
　・神社仏閣の地名から検索できる機能    
　(京都市左京区、京都区北区など……)  
　・抹茶スイーツ店・神社仏閣の詳細ページからそれぞれ近い(半径2km)抹茶スイーツ店と神社仏閣を見ることができる機能  
　・現在地から近い抹茶スイーツと神社仏閣が見ることができる機能   

## MVPリリース以降で実装  

　・ログイン機能、お気に入り、コメント、ツイッター共有機能  
　・自分なりのモデルコース作成・投稿機能・お気にいり機能  
　・現在地から検索機能の拡張(キーワードからの検索機能、現在地からどれだけ時間がかかるか見ることができる機能)     
　・抹茶スイーツ店、神社仏閣の情報の追加  
　・利用規約、プライバシーポリシーの作成   
　・Google Analytics 4の導入  
　・独自ドメイン化  

## ■使用技術  
バッグエンド   
　・Ruby 3.1.2  
　・Ruby on Rails 7.0.3  

フロントエンド    
　・JavaScript  
　・Tailswind CSS-daisyUI    

インフラ    
　・Heroku

使用API  
　・Google Geocoding API(緯度経度の取得に使用)  
　・Google MapsJavaScript API(マップ作成に使用)  

## ■スケジュール
 企画〜技術調査：6/30 〆切  
 README〜ER図作成：7/11 〆切  
 メイン機能実装：7/23 - 9/13  
 β版をRUNTEQ内リリース（MVP）：9/14 〆切  
 本番リリース：9/28
 
## 画面遷移図
[Figma](https://www.figma.com/file/AooAFozghAwS7wKYnJsxmo/%E6%8A%B9%E8%8C%B6%E3%81%A8%E7%A5%9E%E7%A4%BE%E3%80%82%E7%94%BB%E9%9D%A2%E9%81%B7%E7%A7%BB%E5%9B%B3?node-id=0%3A1)

## ER図
[![Image from Gyazo](https://i.gyazo.com/17f0eea322a140bd5b37f37a69da0d30.png)](https://gyazo.com/17f0eea322a140bd5b37f37a69da0d30)
