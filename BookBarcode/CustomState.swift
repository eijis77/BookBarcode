//
//  CustomState.swift

//

import UIKit
import EmptyStateKit

enum State: CustomState {
    
    case barcode
    case empty
    
    var image: UIImage? {
        switch self {
        case .barcode: return UIImage(named: "explain")
        case .empty: return UIImage(named: "item_empty")
            
        }
    }
    
    var title: String? {
        switch self {
        case .barcode: return ""
        case .empty: return ""
        }
    }
    
    var description: String? {
        switch self {
        case .barcode: return "\nメッセージを送って\nトークを開始しましょう！"
        case .empty: return ""
        }
    }
    
   
}
