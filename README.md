# nicochcgi
ニコニコチャンネルの自動キャッシュサーバー

## About
ニコニコチャンネルを監視して、ダウンロードするツールです。  
ダウンロードスクリプトに管理用のcgi、API、プレイヤー、テレビ向けUI等含めます。

## Demonstration
* [メインページ](https://nicocache.github.io/nicoch/)
* [TV向けUI](https://nicocache.github.io/nicoch/tv.html)
* [動画プレイヤー](https://nicocache.github.io/play.html#0)  

最新版とは限りません。静的サイト版。

## How to use
インストール方法
1. nicochフォルダをApacheの公開フォルダ(/var/www/html/nicoch/とか)にコピーします。  
```git clone https://github.com/nicocache/nicochcgi.git```とか。
2. ユーザーを書き換えます。```sudo chown www-data:www-data *```とか。```chlist.*```の3ファイルはcgiが書き換えるので必須です。
3. ```.htaccess```を書き換えます。間違えて外部からアクセスされると犯罪になりかねません。```.htaccess```が有効になるように設定するのも忘れないでください。外部公開するならBasic認証でも掛けておいてください。
4. cgiに実行権限を付与します。```sudo chmod 755 *.cgi *.pl```。
5. cgiが実行できるようにいろんな設定をします。
6. cpanを使って依存ライブラリをインストールします。
7. ```nicoch.conf```を書き換えてダウンロードフォルダを設定します。フォルダはhttpの公開フォルダ外で構いません。ただしcgiが読める場所で。
  * 管理者パスワードが必要な場合は、nicochフォルダ内で``perl get_password.pl``でパスワード用設定を作成して貼り付けてください。
8. ```/var/www-data/.netrc```にニコニコ動画のアカウントを登録します。パスワードを分けた別アカウントを作っておいた方が楽だと思います。.netrcは```chmod 600 .netrc```と```chown www-data:www-data .netrc```でアクセス権を変更してください。
```
machine nicovideo
login foo@bar.com
password your_pass
```
9. 自動ダウンロードを設定します。```sudo -u www-data crontab -e```で```10 3 * * *  perl /var/www/html/nicoch/nico-anime.pl  2>&1 | tee -a ~/nicoch.log ```とか。エコノミーユーザーの場合は低画質の時間は避けましょう。そうでなくてもサーバー負荷を分散するようにするべきです。
10. サムネイル作成用にダウンロードフォルダに``script/mkthumb.sh``を配置し同様にcrontabを設定します。サムネイルはサードパーティーアプリとテレビ向けUI(tv.html)用なので不要ならば必要ありません。

12. ブラウザでアクセスしてみて適当にチャンネルを登録します。

## How to update
アップデート方法
1. サーバーの/nicochフォルダを適当な場所にバックアップします。
2. GitHub上の/nicoch内の以下以外のファイルをコピーします。
  * chlist.txt
  * chlist.bup
  * chlist.tmp
  * nicoch.conf
  * .htaccess
3. 以前のバージョンでは.htaccessでindex.cgiを最優先にしていました。必要ならindex.htmlに書き換えてください。
4. cgiに実行権限を付与。

## play.html
簡単なニコニコ動画のhtmlプレイヤーが含まれています(play.html)。  
同様のニコニコ動画キャッシュサーバーを作る際には手軽なのでお勧めです。

注意点
1. play.htmlはCSSやjavascript含めてスタンドアローンです。
2. コメント取得はサーバー側でプロキシを建てています。動画のやコメントプロキシのUrl指定部分は書き換えてください。
3. コメント表示の挙動がいくらか異なります。簡易版と考えてください。またちょっと重いです。
4. フォントサイズは基本的に実際より小さめにしています。現在としては公式のサイズは大きめだと個人的に思います。

## Apps
### [UWP版クライアント](https://www.microsoft.com/store/productId/9PFMPFTFX4W6)
Windowsで利用できるUWP版のクライアントがあります。
ただし、コメントの表示には対応していません。

* [ストア](https://www.microsoft.com/store/productId/9PFMPFTFX4W6)
* [プロジェクトページ](https://github.com/kurema/NicochViewerUWP)

## Hints
* 動画一覧は単純にファイルシステムを見て判断しています。
録画記録をログ以外に保持しているわけではないので、適当な動画やチャンネルを削除しても問題ありません。
ただし、録画予約に残ったままなら再ダウンロードされます。
* ダウンロードフォルダは容量の大きいパーティションを指定する事をお勧めします。
minidlna等を設定するのもよいでしょう。

## ToDo
1. ~~複数行コメントに対応。ただ本家よりこっちの表示の方が気に入っているので再現性は追及しません。基本このまま。~~ 仮対応しました。
2. ~~アカウント対応。必要性は微妙。~~ 対応しません。
3. getflvでは最高画質にならないので対応。ただしこの程度の方が大量アーカイブには向く。

## License
Gistで公開されていたコードからフォークしているので厳密にはダメかもしれないですが、MITライセンスで公開しています。

## Thanks
[Takumi Akiyama](https://github.com/akiym)様の[nico-anime.pl](https://gist.github.com/akiym/928802)がベースになっています。  
感謝します。  
まぁ大幅に書き加えて別物ですが、スクレイピングとかよく知らなかったので助かりました。
