# nicochcgi
ニコニコチャンネルの自動キャッシュサーバー

## demo
[デモ](https://nicocache.github.io/play.html#0)  
最新版とは限りません。静的サイト版。

## about
ニコニコチャンネルを監視して、ダウンロードするツールです。  
ダウンロードスクリプトに管理用のcgi。

## Hot to use
1. このフォルダ全体をApacheの公開フォルダ(/var/www/html/nicoch/とか)にコピーします。  
```git clone https://github.com/kuremako/nicochcgi.git```とか。
2. ユーザーを書き換えます。```sudo chown www-data:www-data *```とか。```chlist.*```の3ファイルはcgiが書き換えるので必須です。
3. ```.htaccess```を書き換えます。間違えて外部からアクセスされると犯罪になりかねません。```.htaccess```が有効になるように設定するのも忘れないでください。
4. cgiに実行権限を付与します。```sudo chmod 755 *.cgi *.pl```とかです。
5. cgiが実行できるようにいろんな設定をします。
6. cpanを使って依存ライブラリをインストールします。
7. ```nicoch.conf```を書き換えてダウンロードフォルダを設定します。フォルダはhttpの公開フォルダ外で構いません。ただしcgiが読める場所で。
8. ```.netrc```にニコニコ動画のアカウントを登録します。パスワードを分けた別アカウントを作っておいた方が楽だと思います。
```
machine nicovideo
login foo@bar.com
password your_pass
```
9. ```commentproxy.cgi```にもIDとパスワードを設定します。
10. 自動ダウンロードを設定します。```crontab -e```で```10 3 * * 1-5  perl /var/www/html/nicoch/nico-anime.pl >> ~/nicoch.log 2>> ~/nicoch.err.log```とか。エコノミーユーザーの場合は低画質の時間は避けましょう。そうでなくてもサーバー負荷を分散するようにするべきです。
11. ブラウザでアクセスしてみて適当にチャンネルを登録します。

## play.html
簡単なニコニコ動画のhtmlプレイヤーが含まれています(play.html)。  
同様のニコニコ動画キャッシュサーバーを作る際には手軽なのでお勧めです。

注意点
1. play.htmlはCSSやjavascript含めてスタンドアローンです。
2. コメント用のキャンバスサイズは855x481を基本にしています。結構ばらばらにハードコーディングで埋め込んだので、変更な時は置換してください。
3. コメント取得はサーバー側でプロキシを建てています。動画のやコメントプロキシのUrl指定部分は書き換えてください。
4. コメント表示の挙動がいくらか異なります。簡易版と考えてください。またちょっと重いです。

## ToDo
1. ```commentproxy.cgi```を```.netrc```で対応する。調べればわかる気がする。

## License
Gistで公開されていたコードからフォークしているので厳密にはダメかもしれないですが、MITライセンスで公開しています。

## Thanks
[Takumi Akiyama](https://github.com/akiym)様の[nico-anime.pl](https://gist.github.com/akiym/928802)がベースになっています。  
感謝します。  
まぁ大幅に書き加えて別物ですが、スクレイピングとかよく知らなかったので助かりました。
