//
//  SQLKeywords.swift
//  mactable
//

import Foundation

enum SQLKeywords {
    static let common: [String] = [
        "SELECT","FROM","WHERE","INSERT","INTO","VALUES","UPDATE","SET","DELETE",
        "CREATE","TABLE","DROP","ALTER","ADD","COLUMN","INDEX","VIEW","JOIN","LEFT",
        "RIGHT","INNER","OUTER","ON","AS","AND","OR","NOT","NULL","IS","IN","LIKE",
        "BETWEEN","ORDER","BY","GROUP","HAVING","LIMIT","OFFSET","UNION","ALL",
        "DISTINCT","CASE","WHEN","THEN","ELSE","END","CAST","COALESCE","COUNT",
        "SUM","AVG","MIN","MAX","TRUE","FALSE","BEGIN","COMMIT","ROLLBACK","WITH",
        "RETURNING","EXISTS"
    ]
    static let postgres: [String] = ["SERIAL","JSONB","UUID","ILIKE","RETURNING","ARRAY"]
    static let mysql:    [String] = ["AUTO_INCREMENT","ENGINE","CHARSET","UNSIGNED","TINYINT"]
    static let mongo:    [String] = ["db","find","findOne","aggregate","insertOne","updateOne","deleteOne","countDocuments"]

    static func list(for kind: DatabaseKind) -> [String] {
        switch kind {
        case .postgres: return common + postgres
        case .mysql:    return common + mysql
        case .mongodb:  return mongo
        }
    }
}
