//
//  File.swift
//  BookBarcode
//
//  Created by Eiji Shiba on 2021/09/25.
//

import UIKit
import AVFoundation
import Alamofire
import Cartography

class BarcodeLoad: UIViewController {
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "バーコードで書籍登録"
        // Do any additional setup after loading the view.
        let banner_image:UIImage = UIImage(named:"explain")!
        let imageView = UIImageView(image:banner_image)
        self.view.addSubview(imageView)
        constrain(imageView, view) { banner_image, view in
            banner_image.centerX == banner_image.superview!.centerX
            banner_image.centerY == banner_image.superview!.centerY - 20
            banner_image.width == UIScreen.main.bounds.size.width * 0.9
            banner_image.height == UIScreen.main.bounds.size.width * 1.08
        }
        
        let btn = UIButton()
        btn.addTarget(self, action: #selector(onPressButton(_:)), for: .touchUpInside)
        btn.setTitle("書籍を追加する", for: .normal)
        btn.backgroundColor = UIColor.hex(string: "#5498D7", alpha: 1.0)
        btn.setTitleColor(UIColor.white, for: UIControl.State.normal)
        btn.layer.cornerRadius = 10
        self.view.addSubview(btn)
        constrain(btn, imageView) { btn, view in
            btn.centerX == view.centerX
            btn.top == view.bottom + 0
            btn.width == 180
            btn.height == 50
        }

    }
    
    @objc func onPressButton(_ sender : Any){
        
        let next = CaptureViewController()
        next.delegate = self
        
        let nav = UINavigationController(rootViewController: next)
        
        self.present(nav, animated: true, completion: nil)
    }
    
}

extension BarcodeLoad : CaptureViewControllerDelegate {
    
    func capture(_ captureViewController : CaptureViewController, isbn: String?) {
        
        
        //self.isbnTextField.value = isbn
        
        
    }
    
}
