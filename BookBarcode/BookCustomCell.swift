import UIKit
import SDWebImage
import Cartography

// CollectionViewのセル設定
class BookCustomCell: UITableViewCell {
    
    public var title_label = UILabel()
    public var s_state : Int?
    public var cellImageView2: UIImageView?
    public var pubdate = UILabel()
    public var author = UILabel()
    public var publisher = UILabel()
    
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier )
        
        //商品画像のビュー
        var cellImageView2: UIImageView = {
            let imageView2 = UIImageView()
            return imageView2
        }()
        cellImageView2.layer.cornerRadius = 1
        cellImageView2.layer.masksToBounds = true
        cellImageView2.layer.borderColor = UIColor.gray.cgColor
        cellImageView2.layer.borderWidth = 0.1
        contentView.addSubview(cellImageView2)
        constrain(cellImageView2) {image in
            image.width == 75
            image.height == 109
            image.centerY == image.superview!.centerY
            image.left == image.superview!.left + 15
            
        }
        
        self.cellImageView2 = cellImageView2
        
        let fontsize : CGFloat = 15
        
        //タイトル
        let alert_bun = UILabel()
        alert_bun.font = UIFont.systemFont(ofSize: fontsize + 2)
        alert_bun.numberOfLines = 0
        contentView.addSubview(alert_bun)
        constrain(alert_bun,cellImageView2) {label, imageView in
            label.width == label.superview!.width - 120
            label.height >= 0
            label.top == imageView.superview!.top + 7.5
            label.right == label.superview!.right - 15
            
        }
        self.title_label = alert_bun
        
        //著者
        let author = UILabel()
        author.font = UIFont.systemFont(ofSize: fontsize)
        author.numberOfLines = 1
        contentView.addSubview(author)
        constrain(author,alert_bun) {label, last in
            label.width == label.superview!.width - 120
            label.height >= 0
            label.top == last.bottom + 5
            label.left == last.left
        }
        self.author = author
        
        
        //出版社
        let publisher = UILabel()
        publisher.font = UIFont.systemFont(ofSize: fontsize)
        publisher.numberOfLines = 1
        contentView.addSubview(publisher)
        constrain(publisher,author) {label, last in
            label.width == label.superview!.width - 120
            label.height >= 0
            label.top == last.bottom + 5
            label.left == last.left
        }
        self.publisher = publisher
        
        
        
        //出版年
        let alert_time = UILabel()
        alert_time.font = UIFont.systemFont(ofSize: fontsize)
        alert_time.numberOfLines = 1
        contentView.addSubview(alert_time)
        constrain(alert_time,publisher) {label, last in
            label.width == label.superview!.width - 120
            label.height >= 0
            label.top == last.bottom + 5
            label.left == last.left
        }
        self.pubdate = alert_time
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpContents(item : BookInfoModel) {
        
        guard let image = self.cellImageView2 else{ return }
        self.pubdate.text = item.summary.pubdate
        self.author.text = item.summary.author
        self.publisher.text = item.summary.publisher
        image.sd_setImage(with: URL(string: item.summary.cover), placeholderImage: UIImage(named: "dummy"))
        self.title_label.text = item.summary.title
        
    }
}
