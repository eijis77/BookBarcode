//
//  ViewController.swift
//  BookBarcode
//

import UIKit
import Alamofire
import SwiftyJSON
import Alertift
import EmptyStateKit

class BookList: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var largeurl : String?
    var medium_largeurl : String?
    var medium : String?
    var st_thumb150 : String?
    
    var BookArray: [BookInfoModel] = []
    
    var tableView: UITableView?
    fileprivate let refreshCtl = UIRefreshControl()
    
    let activityIndicatorView = UIActivityIndicatorView()
    
    var count = 1
    var count_s = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "登録書籍一覧"
        activityIndicatorView.center = self.view.center
        activityIndicatorView.style = UIActivityIndicatorView.Style.large
        activityIndicatorView.color = .gray
        activityIndicatorView.hidesWhenStopped = true
        self.navigationController?.view.addSubview(activityIndicatorView)
        self.activityIndicatorView.startAnimating()
        // APIリクエストの関数を呼び出す
        getArticles()
        
        self.tableView = {
            let tableView = UITableView(frame: self.view.bounds, style: .plain)
            tableView.autoresizingMask = [
              .flexibleWidth,
              .flexibleHeight
            ]
            tableView.refreshControl = refreshCtl
            refreshCtl.addTarget(self, action: #selector(BookList.refresh(sender:)), for: .valueChanged)
            tableView.delegate = self
            tableView.dataSource = self
            tableView.register(BookCustomCell.self, forCellReuseIdentifier: "Cell")
            self.view.addSubview(tableView)

            return tableView

          }()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getArticles()
        var format = EmptyStateFormat()
        format.imageSize.width = UIScreen.main.bounds.size.width * 0.9
        format.imageSize.height = UIScreen.main.bounds.size.width * 1.08
        view.emptyState.format = format
        if self.BookArray.count == 0 {
            print("empty")
            self.view.emptyState.show(State.empty)
        }
        else {
            print("noempty")
            self.view.emptyState.hide()
        }
    }

    func getArticles() {
        
        let value : [BookInfoModel]? = UserDefaults.standard.codable(forKey: "bookinfokey")
        self.BookArray = []
        self.BookArray.append(contentsOf: value ?? [])
        self.tableView?.reloadData()
        
        self.activityIndicatorView.stopAnimating()
    }
    
    @objc func refresh(sender: UIRefreshControl) {
        getArticles()
        self.refreshCtl.endRefreshing()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        let item = self.BookArray[indexPath.row]
        Alertift.alert(title: "確認", message: "「\(self.BookArray[0].summary.title)」を削除しますか？")
            .action(.destructive("削除する")) { [unowned self] in
                self.activityIndicatorView.startAnimating()
                
                self.BookArray.remove(at: indexPath.row)
                let valueToSave = self.BookArray
                let encoder = JSONEncoder()
                if let encodedValue = try? encoder.encode(valueToSave) {
                    UserDefaults.standard.set(encodedValue, forKey: "bookinfokey")
                }
                getArticles()
                self.activityIndicatorView.stopAnimating()
                
                Alertift.alert(title: "完了", message: "データの削除が完了しました。")
                    .action(.default("OK")) { [unowned self] in
                        if self.BookArray.count == 0 {
                            print("empty")
                            self.view.emptyState.show(State.empty)
                        }
                        else {
                            print("noempty")
                            self.view.emptyState.hide()
                        }
                        
                    }.show(on: self)
                
            }
            .action(.cancel("キャンセル"))
            .show(on: self)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 135
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
      return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return self.BookArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
 
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! BookCustomCell
        let item = self.BookArray[indexPath.row]
        cell.setUpContents(item: item)

      return cell

    }
}
