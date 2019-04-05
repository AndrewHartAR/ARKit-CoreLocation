![ARKit + CoreLocation](https://github.com/ProjectDent/ARKit-CoreLocation/blob/master/arkit.png)

注) 英語から翻訳したものであり、その内容が最新でない場合もあります。最新の情報はオリジナルの英語版を参照してください。

**ARKit**: カメラとモーションデータを使用して、移動したときに精密に近辺の世界を映し出します。

**CoreLocation**: WifiとGPSを使用して、低い精度で現在地を測定します。

**ARKit + CoreLocation**: ARの高い精度とGPSのスケールを組み合わせます。

![Points of interest demo](https://github.com/ProjectDent/ARKit-CoreLocation/blob/master/giphy-1.gif) ![Navigation demo](https://github.com/ProjectDent/ARKit-CoreLocation/blob/master/giphy-2.gif)

これらの技術の組み合わせには非常に大きな可能性があり、さまざまな分野に渡って多くの可能性あるアプリケーションがあります。このライブラリには2つの重要な機能が備わっています。

- 現実世界の座標を用いて、ARの世界にアイテムを置けるようにする機能
- ARの世界を通した動きの知識を組み合わせた最近の位置データを利用した、劇的に改善された位置精度

改善された位置精度は現在、「実験的」な段階にありますが、最も重要な要素になる可能性があります。

やるべきことがまだたくさんあり、他の分野でもそうであるため、GithubのIssueで私たちがやるよりも、このプロジェクトはオープンなコミュニティで提供されるのが最善でしょう。
なので、このライブラリや改善、自分たちの仕事について議論をするために   誰でも参加できるSlackのグループを開こうと思います。

**[Slackのコミュニティに参加してください](https://join.slack.com/t/arcl-dev/shared_invite/enQtNTk4OTg4MzU0MTEyLTMzYTM0Mjk0YmNkMjgwYzg4OWQ1NDFjNjc3NjM1NzdkNWNkZTc2NjQ1MWFiNmI1MTZiMTA5MmNjZmRiOTk1NjI)**

## 必要条件
ARKitはiOS 11が必要で、以下の端末が対応しています。
- iPhone 6S and upwards
- iPhone SE
- iPad (2017)
- All iPad Pro models

iOS 11 は Apple’s Developer websiteからダウンロードできます。

## 利用方法
このライブラリはARKitとCoreLocation frameworkを含んでおり、[Demo 1](https://twitter.com/AndrewProjDent/status/886916872683343872)と似たデモアプリと同様のものです。

[True North calibration のセクションを必ず読んでください。](#true-north-calibration)

### CocoaPodsでの設定
1. Podfileに以下を追加:

`pod 'ARCL'`

2. ターミナルでプロジェクトのフォルダまで移動し、以下を入力:

`pod update`

`pod install`

3. `NSCameraUsageDescription` と `NSLocationWhenInUseUsageDescription` を、簡単な説明を入れてplistに追加 (例はデモをご覧ください)

### マニュアルで設定
1. `ARKit+CoreLocation/Source` からすべてのファイルをプロジェクトに追加.
2. ARKit、SceneKit、CoreLocation、MapKitをインポート
3. `NSCameraUsageDescription` と `NSLocationWhenInUseUsageDescription` を、簡単な説明を入れてplistに追加 (例はデモをご覧ください)

### クリックスタートガイド
例えばロンドンのCanary Wharfなどの、ビルの上にピンを置くためには、ARCLの構築するメインのクラスを使います。 - `SceneLocationView`

まず、ARCLとCoreLocationをインポートします。それから、SceneLocationViewをプロパティとして宣言します。

```swift
import ARCL
import CoreLocation

class ViewController: UIViewController {
var sceneLocationView = SceneLocationView()
}
```

ピントが合ってるときはいつでも `sceneLocationView.run()` を呼び、別のビューに移動したりアプリを閉じたりするなどで中断する場合は `sceneLocationView.pause()` を呼ぶべきです。

```swift
override func viewDidLoad() {
super.viewDidLoad()

sceneLocationView.run()
view.addSubview(sceneLocationView)
}

override func viewDidLayoutSubviews() {
super.viewDidLayoutSubviews()

sceneLocationView.frame = view.bounds
}
```

`run()`を呼んだら、座標を追加することができます。ARCLは`LocationNode`という、3Dシーンのオブジェクトで、現実世界の位置を持ち、3Dの世界の中に適切に表示できるようにする他のいくつかのプロパティも持っているクラスがあります。
`LocationNode` は SceneKitの`SCNNode`のサブクラスで、さらにサブクラス化できます。例えば、`LocationAnnotationNode`というサブクラスを使います。これは3Dの世界に2次元の画像を表示するために使用しますが、いつも使うことになります。

```swift
let coordinate = CLLocationCoordinate2D(latitude: 51.504571, longitude: -0.019717)
let location = CLLocation(coordinate: coordinate, altitude: 300)
let image = UIImage(named: "pin")!

let annotationNode = LocationAnnotationNode(location: location, image: image)
```

UIViewを使用して`LocationAnnotationNode`を初期化することも可能です。 推奨されている方法として、アプリケーションのライフサイクルを動的に保持することもできます。

```swift
let coordinate = CLLocationCoordinate2D(latitude: 51.504571, longitude: -0.019717)
let location = CLLocation(coordinate: coordinate, altitude: 300)
let view = UIView() // or a custom UIView subclass

let annotationNode = LocationAnnotationNode(location: location, view: view)
```

デフォルトで、設置した画像は常に与えられたサイズで見えるべきです。例えば、100x100の画像を与えたなら、それはスクリーン上でも100x100で表示されるでしょう。
遠くにあるアノテーションノードは近くになるのと同じサイズで常に見えるということです。
もし距離に応じて縮小と拡大をさせる方がいいなら、LocationAnnotationNodeの`scaleRelativeToDistance`を`true`にセットすることができます。

```swift
sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
```

シーンに位置ノードを追加する方法は2つあります。それは`addLocationNodeWithConfirmedLocation`と`addLocationNodeForCurrentPosition`を使う方法です。端末と同じ位置に位置ノードを3Dの世界に配置し、座標を与えてくれます。
sceneLocationViewのframeを設定したら、Canary Wharfの上にピンが浮かんでるのが見えます。

ノードが`sceneLocationView`によってタッチされたときに、通知を受け取るためにはViewControllerクラスの`LNTouchDelegate`に従う必要があります。`locationNodeTouched（node：AnnotationNode）`は画面に触れたノードへのアクセスを提供します。`AnnotationNode`はSCNNodeのサブクラスであり、` image：UIImage？ `と` view：UIView？ `の2つの追加プロパティがあります。これらのプロパティはどちらも `LocationAnnotationNode`がどのように初期化されたかに基づいて定められます（UIImageまたはUIViewどちらかのコンストラクタを使ったかによって定められます）。

```swift
class ViewController: UIViewController, LNTouchDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        //...
        self.sceneLocationView.locationNodeTouchDelegate = self
        //...
    }
    func locationNodeTouched(node: AnnotationNode) {
        // Do stuffs with the node instance

        // node could have either node.view or node.image
        if let nodeView = node.view{
            // Do stuffs with the nodeView
            // ...
        }
        if let nodeImage = node.image{
            // Do stuffs with the nodeImage
            // ...
        }
    }
}
```

## 追加機能
ライブラリとデモには、設定のための追加の機能が用意されています。必ず一覧できるように完全に文書化されています。

SceneLocationViewはARSCNViewのサブクラスです. 別の方法で完全にARSCNViewを使えるようにしてくれる一方で、別のクラスにdelegateをセットすべきではないことを留意してください。もしdelegateの機能が必要になったら、サブクラスの`SceneLocationView`を使ってください。

## True North calibration
私が個人的に解決できなかった問題は、iPhoneのTrue North calibrationが現在最高で15度の精度であるということです。これは地図のナビにとっては良いのですが、ARの世界に物体を置くときには、問題となりはじめます。

私はこの問題は、様々なARの技術によって乗り越えられると確信しています。それは共同して恩恵を受けることができると思う1つの領域です。

現在これを改善するために、私は北点を調整できるようにするいくつかの機能をライブラリに追加してきました。
`sceneLocationView.useTrueNorth`を`false`に設定することでこれらを使用します。それから、最初に端末を北の一般的な方向に向けると、合理的に近づけることができます。`UseTrueNorth`をtrue（デフォルト）に設定すると、北をうまく検知できるようになるにつれて調整を続けていきます。

デモアプリ内では、`adjustNorthByTappingSidesOfScreen`という利用できないプロパティがあります。これは上記の機能にアクセスできるのですが、一度利用できるようにすれば、スクリーンの左側と右側をタップすることでシーンの進行方向を調整できるようになります。

自分の位置から直接的にTrue Northとなっている近くの目印を正確にし、座標を使ってそこに物体を設置し、その物体が目印に並んで表示されるまでシーンを調整する`moveSceneHeading`を使います。

## 位置精度の改善
CoreLocationは1~15秒ごとにどこでも位置の更新を伝えてくれますが、精度は150mから4mまで変化します。不正確な位置の読み取りに戻ってしまう前に、ときどき4mや8mのようにより正確な位置を取得することがあるでしょう。それと同時に、ARはモーションやカメラのデータを使ってARの世界での地図を作ります。

ユーザーは4mまで正確な位置の読み取りを受信することがあります。その後、ユーザーが10m北に歩き、65mまで正確に読み取られた別の位置を取得します。この65mでの正確な読み取りはCoreLicationが提供できる最高のものなのですが、4mが読み取られたときにAR内でのユーザーの位置を把握し、そこからARを10m北に歩いたら、およそ4mの精度で新しい座標を与えてくれるデータに変換することができます。これは100mまで正確になります。

[より詳細な情報はwikiにあります。](https://github.com/ProjectDent/ARKit-CoreLocation/wiki/Current-Location-Accuracy).

### 問題
これは実験的だと言いましたが、現在はユーザーがARを使って歩いてるときにARKitがときどき混乱し、ユーザーの位置が不正確になるかもしれません。この問題は"オイラー角"または端末の向きの情報に影響するようにも見えます。なので、少し距離を進んだ後は、あなたが別の方角を歩いてるとARKitは思うのかもしれません。

AppleがそのうちARKitを改善する一方で、それらの問題を回避するために私たちでできる改善があると思っています。例えば問題が起きたことを認識し、修正することなど。これは位置データを想定した位置と比較して、想定した範囲を超えて移動したのかどうかを判定することで実現できます。

### 位置のアルゴリスムの改善
ユーザの位置を決定するためにさらなる最適化をすることができます。

例えば、最近の位置データを見て、その後のユーザーの移動をもとに各データポイントを変換し、ユーザがいそうな位置をより厳しく判定するためにそのデータポイントの重なりを使うというテクニックです。

[より詳細な情報はwikiにあります。](https://github.com/ProjectDent/ARKit-CoreLocation/wiki/Current-Location-Accuracy).

## 今後

私たちは、いくつかのマイルストーンと上記に関連した問題を抱えています。議論したり貢献することは誰でも歓迎です。心おきなくプルリクエストを送ってください。新しくIssueを追加するか[the Slack community](https://join.slack.com/t/arcl-dev/shared_invite/MjE4NTQ3NzE3MzgxLTE1MDExNTAzMTUtMTIyMmNlMTkyYg)で新しい機能/拡張/バグについて議論できます。

## Thanks
[@AndrewProjDent](https://twitter.com/andrewprojdent)がライブラリをつくりましたが、コミュニティの努力はここからです。

[MIT License](http://opensource.org/licenses/MIT)の条件でオープンソースとして利用できます。

