//
//  CaptureViewControllerDelegate.swift

import UIKit
import AVFoundation
import Alamofire
import Cartography
import Alertift

protocol CaptureViewControllerDelegate : AnyObject {
    
    func capture(_ captureViewController : CaptureViewController, isbn: String?)
    
}


class CaptureViewController : UIViewController {
    
    let detectionArea = UIView()
    let ex_label = UILabel()
    
    var BookInfo: [BookInfoModel]? = nil
    
    var activityIndicatorView = UIActivityIndicatorView()

    let x: CGFloat = 0.05
    let y: CGFloat = 0.4
    let width: CGFloat = 0.9
    let height: CGFloat = 0.15
    
    weak var delegate : CaptureViewControllerDelegate? = nil
    
    var captureSession : AVCaptureSession?
    
    var videoLayer : AVCaptureVideoPreviewLayer?
    var isbn : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "バーコード読み取り"
        self.view.backgroundColor = .white
        self.navigationItem.rightBarButtonItem = {
            let btn = UIBarButtonItem(title: "完了", style: .plain, target: self, action: #selector(onPressComplete(_:)))
            return btn
        }()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.captureSession?.stopRunning()
        self.captureSession = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.startCapture()
        
        //枠線の表示
        detectionArea.frame = CGRect(x: view.frame.size.width * x, y: view.frame.size.height * y, width: view.frame.size.width * width, height: view.frame.size.height * height)
        detectionArea.layer.borderColor = UIColor.red.cgColor
        detectionArea.layer.borderWidth = 4
        detectionArea.layer.cornerRadius = 6
        detectionArea.clipsToBounds = true
        self.view.addSubview(detectionArea)
        
        ex_label.text = "「978」から始まる13桁の\nバーコードをかざしてください"
        ex_label.numberOfLines = 0
        ex_label.textColor = UIColor.hex(string: "#ffffff", alpha: 1)
        ex_label.font = UIFont.boldSystemFont(ofSize: 17.0)
        self.view.addSubview(ex_label)
        constrain(ex_label, detectionArea) { label, view in
            label.width  <= self.view.frame.size.width * width
            label.height >= 0
            label.bottom == view.top - 5
            label.centerX == view.centerX
        }
    }
    
    @objc func onPressComplete(_ sender : Any){
        self.captureSession?.stopRunning()
        self.captureSession = nil
        self.dismiss(animated: true, completion: nil)
    }
    
    func startCapture(){
        
        let session = AVCaptureSession()
        
        //videoの取得
        guard let device : AVCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("no video device")
            return
        }
        
        //inputの取得
        guard let input : AVCaptureInput = try? AVCaptureDeviceInput(device: device) else {
            print("faild to get input")
            return
        }
        
        //inputをセッションに追加
        session.addInput(input)
        
        //outputをセッションに追加
        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        
        //outputの設定(delegateの設定)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        //ouputの設定(何を検出するか JAN=EAN 短縮用は書籍だと使わないけど一応)
        output.metadataObjectTypes = [.ean8, .ean13]
        
        // 検出エリアの設定
        output.rectOfInterest = CGRect(x: y,y: 1-x-width,width: height,height: width)
        
        //captureを開始
        session.startRunning()
        
        //画面上に表示するのにvideoLayerを作る
        let videoLayer = AVCaptureVideoPreviewLayer(session: session)
        videoLayer.videoGravity = .resizeAspectFill
        videoLayer.frame = self.view.bounds
        
        //videoLayerを追加する
        self.videoLayer = videoLayer
        self.view.layer.addSublayer(videoLayer)
        
        //開放用に保持
        self.captureSession = session
        
    }
}

extension CaptureViewController : AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection){
        
        //バーコードが検出されたらここが呼び出される
        
        for metadataObject in metadataObjects {
            guard self.videoLayer?.transformedMetadataObject(for: metadataObject) is AVMetadataMachineReadableCodeObject else { continue }
            guard let object = metadataObject as? AVMetadataMachineReadableCodeObject else {
                continue
            }
            guard let detectionString = object.stringValue else {
                continue
            }
            
            print("detectionString=\(detectionString) type=\(object.type.rawValue)")
            
            //書籍だと978から始まるだと限定出来る
            //参考）https://www.a-poc.co.jp/howto/howto_faq20.html
            
            if detectionString.starts(with: "978") && detectionString.count == 13 {
                //self.isbn = detectionString
                self.isbn = detectionString
            }
        }
        //
        if self.isbn != nil {
            DispatchQueue.global().async {
                self.getBookinfo(isbnCode: self.isbn!)
            }
            
            activityIndicatorView.center = view.center
            activityIndicatorView.style = .large
            activityIndicatorView.color = .white
            view.addSubview(activityIndicatorView)
            activityIndicatorView.startAnimating()
            
            detectionArea.layer.borderColor = UIColor.white.cgColor
            detectionArea.layer.borderWidth = 4
            wait( { return self.BookInfo == nil } ) {
            
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.captureSession?.stopRunning()
                    self.captureSession = nil
                    self.delegate?.capture(self, isbn: self.isbn)
                    self.activityIndicatorView.stopAnimating()
                    Alertift.alert(title: "確認", message: "『\(self.BookInfo![0].summary.title)』\nで間違いありませんか？")
                                .action(.default("保存する")) { [unowned self] in
                                    self.captureSession = nil
                                    
                                    //現在のローカルを取得
                                    let value : [BookInfoModel]? = UserDefaults.standard.codable(forKey: "bookinfokey")
                                    
                                    var flag = false
                                    //ローカルと新規読み込みが重複していないか確認
                                    if value != nil {
                                        for i in 0..<value!.count{
                                            if value![i].summary.cover == self.BookInfo![0].summary.cover{
                                                flag = true
                                            }
                                        }
                                    }
                                    //重複していない場合に追加処理
                                    if flag == false{
                                        var new_struct = value
                                        new_struct?.append(contentsOf: self.BookInfo ?? [])
                                        /// 保存
                                        let valueToSave = new_struct
                                        let encoder = JSONEncoder()
                                        if let encodedValue = try? encoder.encode(valueToSave) {
                                            UserDefaults.standard.set(encodedValue, forKey: "bookinfokey")
                                            self.dismiss(animated: true, completion: nil)
                                        }
                                    }
                                    else{
                                        Alertift.alert(title: "重複", message: "すでに追加してある書籍です。")
                                            .action(.default("OK")) { [unowned self] in
                                                self.dismiss(animated: true, completion: nil)
                                            }
                                            .show(on: self)
                                    }
                                    
                                    
                                }
                                .action(.cancel("キャンセル")) {
                                    self.isbn = nil
                                    self.BookInfo = nil
                                    self.startCapture()
                                    //枠線の表示
                                    self.detectionArea.frame = CGRect(x: self.view.frame.size.width * self.x, y: self.view.frame.size.height * self.y, width: self.view.frame.size.width * self.width, height: self.view.frame.size.height * self.height)
                                    self.detectionArea.layer.borderColor = UIColor.red.cgColor
                                    self.detectionArea.layer.borderWidth = 4
                                    self.detectionArea.layer.cornerRadius = 6
                                    self.detectionArea.clipsToBounds = true
                                    self.view.addSubview(self.detectionArea)
                                    self.ex_label.text = "「978」から始まる13桁の\nバーコードをかざしてください"
                                    self.ex_label.numberOfLines = 0
                                    self.ex_label.textColor = UIColor.hex(string: "#ffffff", alpha: 1)
                                    self.ex_label.font = UIFont.boldSystemFont(ofSize: 17.0)
                                    self.view.addSubview(self.ex_label)
                                    constrain(self.ex_label, self.detectionArea) { label, view in
                                        label.width  <= self.view.frame.size.width * self.width
                                        label.height >= 0
                                        label.bottom == view.top - 5
                                        label.centerX == view.centerX
                                    }
                                }.show(on: self)
                }
            }
        }
        
    }
    private func getBookinfo(isbnCode: String) {

        let baseUrl = "https://api.openbd.jp/v1/"
        let searchUrl = "\(baseUrl)get"
        let parameters: [String: Any] = ["isbn": isbnCode]
        let headers: HTTPHeaders = ["Content-Type": "application/json"]
        AF.request(searchUrl, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).responseJSON { response in
            guard let data = response.data else {
                return
            }
            do {
                let bookinfo: [BookInfoModel] = try JSONDecoder().decode([BookInfoModel].self, from: data)
                self.BookInfo = bookinfo
                print([bookinfo[0]])
            } catch let error {
                print("SummaryERROR: \(error)")
                self.activityIndicatorView.stopAnimating()
                Alertift.alert(title: "エラー", message: "申し訳ございません。未対応の書籍です。\n出版年が最近の書籍は未対応であるケースがございますのでご注意ください。")
                    .action(.default("OK")) { [unowned self] in
                        self.isbn = nil
                        self.BookInfo = nil
                        self.startCapture()
                        //枠線の表示
                        self.detectionArea.frame = CGRect(x: self.view.frame.size.width * self.x, y: self.view.frame.size.height * self.y, width: self.view.frame.size.width * self.width, height: self.view.frame.size.height * self.height)
                        self.detectionArea.layer.borderColor = UIColor.red.cgColor
                        self.detectionArea.layer.borderWidth = 4
                        self.detectionArea.layer.cornerRadius = 6
                        self.detectionArea.clipsToBounds = true
                        self.view.addSubview(self.detectionArea)
                        self.ex_label.text = "「978」から始まる13桁の\nバーコードをかざしてください"
                        self.ex_label.numberOfLines = 0
                        self.ex_label.textColor = UIColor.hex(string: "#ffffff", alpha: 1)
                        self.ex_label.font = UIFont.boldSystemFont(ofSize: 17.0)
                        self.view.addSubview(self.ex_label)
                        constrain(self.ex_label, self.detectionArea) { label, view in
                            label.width  <= self.view.frame.size.width * self.width
                            label.height >= 0
                            label.bottom == view.top - 5
                            label.centerX == view.centerX
                        }
                    }
                    .show(on: self)
            }
        }
    }
    
    func wait(_ waitContinuation: @escaping (()->Bool), compleation: @escaping (()->Void)) {
        var wait = waitContinuation()
        // 0.01秒周期で待機条件をクリアするまで待ちます。
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            while wait {
                DispatchQueue.main.async {
                    wait = waitContinuation()
                    semaphore.signal()
                }
                semaphore.wait()
                Thread.sleep(forTimeInterval: 0.01)
            }
            // 待機条件をクリアしたので通過後の処理を行います。
            DispatchQueue.main.async {
                compleation()
            }
        }
    }

}
