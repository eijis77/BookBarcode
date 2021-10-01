

import Foundation

struct BookInfoModel: Codable {
    var summary: ItemSummary
}

struct ItemSummary: Codable{
    var title: String
    var publisher: String
    var pubdate: String
    var cover: String
    var author: String
}

extension Encodable {

    var json: Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }
}

extension Decodable {

    static func decode(json data: Data?) -> Self? {
        guard let data = data else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(Self.self, from: data)
    }
}

extension UserDefaults {

    /// - Warning:
    /// 2020.11.30追記) setCodable ではなく set という関数名にすると、String をセットしたいときに Codable と衝突して Codable 扱いとなってしまうため注意。
    func setCodable(_ value: Codable?, forKey key: String) {
        guard let json: Any = value?.json else { return } // 2020.02.23 追記参照
        self.set(json, forKey: key)
        synchronize()
    }

    func codable<T: Codable>(forKey key: String) -> T? {
        let data = self.data(forKey: key)
        let object = T.decode(json: data)
        return object
    }
}
