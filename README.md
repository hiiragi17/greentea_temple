![badge](https://img.shields.io/badge/thank%20you-for%20visiting-brightgreen)
<br>
[![Rails](https://img.shields.io/badge/Rails-v7.0.3-%23a72332)](https://rubygems.org/gems/rails/versions/7.0.3)

# 抹茶と神社。

<img src="https://user-images.githubusercontent.com/94298144/189052247-e5390c19-8701-49c7-83ec-3e9793c8d363.png" width="400" height="400">
サービスURL:https://www.matcha-to-jinja.com/

# ■ サービス概要
　京都にある抹茶スイーツのお店の近くにある神社仏閣を調べたり、  
　京都にある神社仏閣近くの抹茶スイーツを調べたりすることができ、  
　現在地近くにある抹茶スイーツ店と神社仏閣を調べることができ、  
　また自分だけの抹茶スイーツと神社仏閣のモデルルートが作成出来るサービスです。  

<details>
<summary>ユーザーが抱える課題</summary>
　折角京都に観光に来るなら、<br>  
　京都で有名な抹茶スイーツを食べ、神社仏閣を同時に巡りたいと考えるユーザーは多いと考えられる。<br>  
　しかし抹茶スイーツをまとめたサイトや、神社仏閣をまとめたサイトはあっても、<br>  
　それら二つを同時に見られるサイトはあまりない。<bt>  
　その為それら二つを同時に探すことができ、<br>  
　尚且つ行きたい箇所の距離や行き方を調べたりすることができるようにしたい。<br>  
</details>

<details>
<summary>解決方法</summary>
　・興味のあるスイーツのジャンルから抹茶スイーツを探すことができる<br>  
　・行く予定のある地域の神社仏閣を調べることができる<br>  
　・行きたい抹茶スイーツ店近くの神社仏閣、行きたい神社仏閣近くの抹茶スイーツ店を知ることができる<br>  
　・現在地から行ける抹茶スイーツ店、神社仏閣を調べることができる<br>     
</details>
　

# ■機能に関して  

## 1. 抹茶スイーツと神社仏閣が検索できる
抹茶スイーツはキーワードとスイーツのカテゴリで、<br>
神社仏閣はキーワードと地域で検索ができます。<br>
一覧ページでは施設の名前、カテゴリ(地域)、住所、アクセス、定休日をわかるようにしており、<br>
気になったら詳細ページに飛べるようになっています。<br>

| 抹茶スイーツの検索 | 神社仏閣の検索 |
|:---:|:---:|
|　![抹茶スイーツ検索](https://user-images.githubusercontent.com/94298144/205436531-9905b312-1e17-434b-8d9a-423294f814d6.gif)　|　![神社仏閣検索](https://user-images.githubusercontent.com/94298144/205436544-5401e888-3629-4817-a576-a963c7f4d41a.gif)　|

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

## 画面遷移図
[Figma](https://www.figma.com/file/AooAFozghAwS7wKYnJsxmo/%E6%8A%B9%E8%8C%B6%E3%81%A8%E7%A5%9E%E7%A4%BE%E3%80%82%E7%94%BB%E9%9D%A2%E9%81%B7%E7%A7%BB%E5%9B%B3?node-id=0%3A1)

## ER図
[![Image from Gyazo](https://i.gyazo.com/17f0eea322a140bd5b37f37a69da0d30.png)](https://gyazo.com/17f0eea322a140bd5b37f37a69da0d30)
