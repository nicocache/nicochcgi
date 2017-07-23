# nicochcgi
ニコニコチャンネルの自動キャッシュサーバー

## about
ニコニコチャンネルを監視して、ダウンロードするツールです。  
ダウンロードスクリプトに管理用のcgi。

## Hot to use
1. このフォルダ全体をHTTPサーバー(Apacheとか)の公開フォルダ(/var/www/html/nicoch/とか)にコピーします。  
```git clone git@github.com:kuremako/nicochcgi.git```とか。
2. ユーザーを書き換えます。```sudo chown www-data:www-data *```とか。```chlist.*```の3ファイルはcgiが書き換えるので必須です。
3. ```.htaccess```を書き換えます。間違えて外部からアクセスされると犯罪になりかねません。```.htaccess```が有効になるように設定するのも忘れないでください。
4. cgiに実行権限を付与します。```sudo chmod 755 *.cgi *.pl```とかです。
5. cgiが実行できるようにいろんな設定をします。
6. ```nicoch.conf```を書き換えてダウンロードフォルダを設定します。フォルダはhttpの公開フォルダ外で構いません。ただしcgiが読める場所で。
7. ```.netrc```にニコニコ動画のアカウントを登録します。パスワードを分けた別アカウントを作っておいた方が楽だと思います。
```
machine nicovideo
login foo@bar.com
password your_pass
```
8. ```commentproxy.cgi```にもIDとパスワードを設定します。
9. 自動ダウンロードを設定します。```crontab -e```で```10 3 * * 1-5  perl /var/www/html/nicoch/nico-anime.pl >> ~/nicoch.log 2>> ~/nicoch.err.log```とか。エコノミーユーザーの場合は低画質の時間は避けましょう。そうでなくてもサーバー負荷を分散するようにするべきです。
10. ブラウザでアクセスしてみて適当にチャンネルを登録します。

## ToDo
1. ```commentproxy.cgi```を```.netrc```で対応する。調べればわかる気がする。

## License
Gistで公開されていたコードからフォークしているので厳密にはダメかもしれないですが、MITライセンスで公開しています。

## Thanks
[Takumi Akiyama](https://github.com/akiym)様の[nico-anime.pl](https://gist.github.com/akiym/928802)がベースになっています。  
感謝します。  
まぁ大幅に書き加えて別物ですが、スクレイピングとかよく知らなかったので助かりました。
