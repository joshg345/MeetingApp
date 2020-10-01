//
//  JWPUB.swift
//  MeetingApp
//
//  Created by Joshua on 16/03/2020.
//  Copyright © 2020 Josh. All rights reserved.
//

import Foundation
import Zip
import SwiftyJSON
import SwiftUI
import SQLite

extension String {

    func slice(from: String, to: String) -> String? {
        guard let rangeFrom = range(of: from)?.upperBound else { return nil }
        guard let rangeTo = self[rangeFrom...].range(of: to)?.lowerBound else { return nil }
        return String(self[rangeFrom..<rangeTo])
    }
    
    subscript(_ range: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        let end = index(start, offsetBy: min(self.count - range.lowerBound,
                                             range.upperBound - range.lowerBound))
        return String(self[start..<end])
    }

    subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
         return String(self[start...])
    }

}

class JWPUB: NSObject, URLSessionDelegate, URLSessionDownloadDelegate{
    
var suggestedFileName: URL!
var downloadsFileName: URL!
var issue: String = ""
@State private var language = UserDefaults.standard.string(forKey: "savedLanguage")
@ObservedObject var globalScrollTitle: ScrollTitle = ScrollTitle.sharedInstance
    
    func getCurrMonth(number: Bool, ahead: Int) -> String{
        let now = Date()
        let dateFormatter = DateFormatter()
        var nameOfMonth = String()
        var nameOfMonthDate = Date()
        if number == true{
            dateFormatter.dateFormat = "MM"
        } else{
            dateFormatter.dateFormat = "LLLL"
        }
        if ahead == 0 {
            nameOfMonth = dateFormatter.string(from: now)
        } else if ahead == 1 {
            nameOfMonthDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
            nameOfMonth = dateFormatter.string(from: nameOfMonthDate)
        } else if ahead == 2 {
             nameOfMonthDate = Calendar.current.date(byAdding: .month,value: 2, to: Date())!
            nameOfMonth = dateFormatter.string(from: nameOfMonthDate)
        }
        return nameOfMonth
    }
    
    func New(url: String, completion: @escaping () -> Void){

        let myUrl = URL(string: url)!
        let request = URLRequest(url:myUrl)
        let config = URLSessionConfiguration.default
        let operationQueue = OperationQueue()
        let session = URLSession(configuration: config, delegate: self, delegateQueue: operationQueue)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print(error!)
                return
            }
            // Success
            if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                print("Success: \(statusCode)")
            }

            do {
                let documentFolderURL = try FileManager.default.url(for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let fileURL = documentFolderURL.appendingPathComponent((response?.suggestedFilename)!)
                self.suggestedFileName = fileURL
                self.downloadsFileName = documentFolderURL
                try data!.write(to: fileURL)

                DispatchQueue.main.async {

                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        print("file present!") // Confirm that the file is here!
                    }
                }
                
                completion()
            } catch  {
                print("error writing file \(error)")
            }
        }
        task.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // check for and handle errors:
        // * downloadTask.response should be an HTTPURLResponse with statusCode in 200..<299
        print("download complete!")
    
        do{
            let downloadedData = try Data(contentsOf: location)

            DispatchQueue.main.async(execute: {
                print("transfer completion OK!")

                let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true).first! as NSString
                let destinationPath = documentDirectoryPath.appendingPathComponent((downloadTask.response?.suggestedFilename)!)

                let pdfFileURL = URL(fileURLWithPath: destinationPath)
                FileManager.default.createFile(atPath: pdfFileURL.path,
                                               contents: downloadedData,
                                               attributes: nil)

                if FileManager.default.fileExists(atPath: pdfFileURL.path) {
                    print("file present!") // Confirm that the file is here!
                }
            })
        } catch {
            print (error.localizedDescription)
        }
        
        
    }
    
    func unzip(url: URL)
    {
        do{
//            let newURL = url.deletingPathExtension().appendingPathExtension("JWPUB")
//            try FileManager.default.moveItem(at: url, to: newURL)
//            //sleep(50)
            Zip.addCustomFileExtension("jwpub")
            Zip.addCustomFileExtension("")
            let documentsDirectory = FileManager.default.urls(for:.downloadsDirectory, in: .userDomainMask)[0]
            try Zip.unzipFile(url, destination: documentsDirectory, overwrite: true, password: "", progress: { (progress) -> () in
                print(progress)
            })
            //let unzipDirectory = try Zip.quickUnzipFile(url)
            //let contents = url.deletingPathExtension().appendingPathComponent("contents")
            //print (contents)
        } catch{
            print (error)
        }
    }
    
    func GetMWBUrl(issue: String, language: String, completion: @escaping (String) -> Void){
        let url = URL(string: "https://pubmedia.jw-api.org/GETPUBMEDIALINKS?issue=" + issue + "&output=json&pub=mwb&fileformat=PDF%2CEPUB%2CJWPUB%2CRTF%2CTXT%2CBRL%2CBES&alllangs=0&langwritten=" + language + "&txtCMSLang=" + language)
        
        //let config = URLSessionConfiguration.default
        //let operationQueue = OperationQueue()
        //let session = URLSession(configuration: config, delegate: self, delegateQueue: operationQueue)
        var JWPUBurl: String = ""
        
        
        URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            guard let data = data else { return }
            do{
                let json = try JSON(data: data)
                JWPUBurl = json["files"][language]["JWPUB"][0]["file"]["url"].string!
                completion(JWPUBurl)
            } catch {
                print(error)
            }
            
            }).resume()
    }
    
    func doesMWBExist() -> Bool {
        let downloadUrl = FileManager.default.urls(for:.downloadsDirectory, in: .userDomainMask)[0]
        var path: URL
        path = downloadUrl.appendingPathComponent("mwb_" + language! + "_" + issue + ".db")
        if FileManager.default.fileExists(atPath: path.path) {
            return true
        }
        else{
            return false
        }
    }
    
    func GetWTUrl(issue: String, language: String, completion: @escaping (String) -> Void){
        let url = URL(string: "https://pubmedia.jw-api.org/GETPUBMEDIALINKS?issue=" + issue + "&output=json&pub=w&fileformat=PDF%2CEPUB%2CJWPUB%2CRTF%2CTXT%2CBRL%2CBES&alllangs=0&langwritten=" + language + "&txtCMSLang=" + language)
        
        //let config = URLSessionConfiguration.default
        //let operationQueue = OperationQueue()
        //let session = URLSession(configuration: config, delegate: self, delegateQueue: operationQueue)
        var JWPUBurl: String = ""
        
        
        URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            guard let data = data else { return }
            do{
                let json = try JSON(data: data)
                JWPUBurl = json["files"][language]["JWPUB"][0]["file"]["url"].string!
                completion(JWPUBurl)
            } catch {
                print(error)
            }
            
            }).resume()
    }
    

    func getWeekData(issue: String, language: String){
    
        
        let downloadUrl = FileManager.default.urls(for:.downloadsDirectory, in: .userDomainMask)[0]
        var path: URL
        
        if issue == "" {
            path = downloadUrl.appendingPathComponent("custom.db")
            do{
                let db = try Connection(path.absoluteString)
                let NameTable = Table("Name")
                let Name = Expression<String>("Name")
                let DocumentID = Expression<Int>("DocumentID")
                let weekDataFunc1 = weekDataFunc()
                
                for name in try db.prepare(NameTable) {
                    weekDataFunc1.addCustom(name: name[Name],documentID: name[DocumentID])
                }
            } catch{
                print(error)
            }

        }
        else {
            path = downloadUrl.appendingPathComponent("mwb_" + language + "_" + issue + ".db")
            
            do{
                let db = try Connection(path.absoluteString)
                let DatedText = Table("DatedText")
                let FirstDateOffset = Expression<Int>("FirstDateOffset")
                let LastDateOffset = Expression<Int>("LastDateOffset")
                let DocumentID = Expression<Int>("DocumentId")
                let weekDataFunc1 = weekDataFunc()
                
                for date in try db.prepare(DatedText) {
                    weekDataFunc1.populateArray(startDate: date[FirstDateOffset],endDate: date[LastDateOffset],documentID: date[DocumentID])
                }
            } catch{
                print(error)
            }
        }

    }
    
    func getLastDocumentIDMultimedia() -> Int{
        
        var array = [Int]()
        let downloadUrl = FileManager.default.urls(for:.downloadsDirectory, in: .userDomainMask)[0]
        //let pathlanguage = language!
        let path = downloadUrl.appendingPathComponent("mwb_" + language! + "_" + issue + ".db")
        
        do{
            let db = try Connection(path.absoluteString)
            let documentMultimediaTable = Table("DocumentMultimedia")
            let documentIdField = Expression<Int>("DocumentId")
            
            for media in try db.prepare(documentMultimediaTable.select(documentIdField)) {
                array.append(media[documentIdField])
            }
        } catch{
            print(error)
        }
        return array.endIndex - 1
    }
    
    func getLastDocumentMultimediaID() -> Int{
        
        var array = [Int]()
        let downloadUrl = FileManager.default.urls(for:.downloadsDirectory, in: .userDomainMask)[0]
        //let pathlanguage = language!
        let path = downloadUrl.appendingPathComponent("mwb_" + language! + "_" + issue + ".db")
        
        do{
            let db = try Connection(path.absoluteString)
            let documentMultimediaTable = Table("DocumentMultimedia")
            let documentMultimediaId = Expression<Int>("DocumentMultimediaId")
            
            for media in try db.prepare(documentMultimediaTable.select(documentMultimediaId)) {
                array.append(media[documentMultimediaId])
            }
        } catch{
            print(error)
        }
        return array.endIndex - 1
    }
    
    func insert_DocumentMultimedia(){
        
        let downloadUrl = FileManager.default.urls(for:.downloadsDirectory, in: .userDomainMask)[0]
        let path = downloadUrl.appendingPathComponent("mwb_" + language! + "_" + issue + ".db")
        do{
            let db = try Connection(path.absoluteString)
            let documentMultimediaTable = Table("DocumentMultimedia")
            let documentMultimediaIdField = Expression<Int>("DocumentMultimediaId")
            let documentIdField = Expression<Int>("DocumentId")
            let multimediaIdField = Expression<Int>("MultimediaId")
            
            let lastDocumentMultimediaID = getLastDocumentMultimediaID()
            
            let insert = documentMultimediaTable.insert(documentMultimediaIdField <- lastDocumentMultimediaID + 1, documentIdField <- globalScrollTitle.documentId, multimediaIdField <- lastDocumentMultimediaID + 1)
            try db.run(insert)
        }
        catch{
            print(error)
        }
    }
        
    func search_DocumentMultimedia(documentId: Int, nextDocumentId: Int) -> Array<Int>{
        
        var array = [Int]()
        let downloadUrl = FileManager.default.urls(for:.downloadsDirectory, in: .userDomainMask)[0]
        let path = downloadUrl.appendingPathComponent("mwb_" + language! + "_" + issue + ".db")
        
        if documentId != nextDocumentId && documentId + 1 != nextDocumentId{
            //let difference = nextDocumentId - documentId
            //var missedDocumentId = documentId + 1
            
            for n in documentId...nextDocumentId - 1{
            
                do{
                    let db = try Connection(path.absoluteString)
                    let documentMultimediaTable = Table("DocumentMultimedia")
                    let documentMultimediaIdField = Expression<Int>("DocumentMultimediaId")
                    let documentIdField = Expression<Int>("DocumentId")
                    
                    
                    for media in try db.prepare(documentMultimediaTable.select(documentMultimediaIdField, documentIdField).where(documentIdField == n)) {
                        array.append(media[documentMultimediaIdField])
                    }
                } catch{
                    print(error)
                }
                //missedDocumentId = missedDocumentId + 1
            }
        }
        else {
            
            let lastDocumentId = weekDataF.getLastDocumentId()
            
            if documentId == lastDocumentId{
                
                for n in documentId...getLastDocumentIDMultimedia() {
                    do{
                        let db = try Connection(path.absoluteString)
                        let documentMultimediaTable = Table("DocumentMultimedia")
                        let documentMultimediaIdField = Expression<Int>("DocumentMultimediaId")
                        let documentIdField = Expression<Int>("DocumentId")
                        
                        
                        for media in try db.prepare(documentMultimediaTable.select(documentMultimediaIdField, documentIdField).where(documentIdField == n)) {
                            array.append(media[documentMultimediaIdField])
                        }
                    } catch{
                        print(error)
                    }
                }
            }
            else {
            
                do{
                    let db = try Connection(path.absoluteString)
                    let documentMultimediaTable = Table("DocumentMultimedia")
                    let documentMultimediaIdField = Expression<Int>("DocumentMultimediaId")
                    let documentIdField = Expression<Int>("DocumentId")
                    
                    
                    for media in try db.prepare(documentMultimediaTable.select(documentMultimediaIdField, documentIdField).where(documentIdField == documentId)) {
                        array.append(media[documentMultimediaIdField])
                    }
                } catch{
                    print(error)
                }
            }
        }
        
        return array
    }
    
    func search_CustomMedia(documentID: Int) -> Array<mediaData>{
        
        var array = [mediaData]()
        let downloadUrl = FileManager.default.urls(for:.downloadsDirectory, in: .userDomainMask)[0]
        let path = downloadUrl.appendingPathComponent("custom.db")
            
            do{
                let db = try Connection(path.absoluteString)
                let documentMultimediaTable = Table("Multimedia")
                let DocumentIdField = Expression<Int>("DocumentID")
                let MultimediaIdField = Expression<Int>("MultimediaID")
                let keySymbol = Expression<String?>("KeySymbol")
                let track = Expression<Int?>("Track")
                let issueTagNumber = Expression<Int?>("IssueTagNumber")
                let mimeType = Expression<String>("MimeType")
                let filePath = Expression<String?>("FilePath")
                let meps = Expression<Int?>("MepsDocumentId")
                
                for media in try db.prepare(documentMultimediaTable.select(MultimediaIdField, keySymbol, track, issueTagNumber, mimeType, filePath, meps).where(DocumentIdField == documentID)) {
                    let data = mediaData(mediaID: media[MultimediaIdField], mediaType: media[keySymbol], track: media[track], issueTagNumber: media[issueTagNumber] ?? 0, mimeType: media[mimeType], filePath: media[filePath] ?? "", meps: media[meps] ?? 0)
                    array.append(data)
                }
            } catch{
                print(error)
            }
        
        return array
    }
    
    func search_Multimedia(multimediaID: [Int]) -> Array<mediaData>{
        
        var array = [mediaData]()
        let downloadUrl = FileManager.default.urls(for:.downloadsDirectory, in: .userDomainMask)[0]
        let path = downloadUrl.appendingPathComponent("mwb_" + language! + "_" + issue + ".db")
        
        for index in 0 ..< multimediaID.count {
            
            do{
                let db = try Connection(path.absoluteString)
                let documentMultimediaTable = Table("Multimedia")
                let MultimediaIdField = Expression<Int>("MultimediaId")
                let keySymbol = Expression<String?>("KeySymbol")
                let track = Expression<Int?>("Track")
                let issueTagNumber = Expression<Int>("IssueTagNumber")
                let mimeType = Expression<String>("MimeType")
                let filePath = Expression<String>("FilePath")
                let meps = Expression<Int?>("MepsDocumentId")
                
                for media in try db.prepare(documentMultimediaTable.select(MultimediaIdField, keySymbol, track, issueTagNumber, mimeType, filePath, meps).where(MultimediaIdField == multimediaID[index])) {
                    let data = mediaData(mediaID: media[MultimediaIdField], mediaType: media[keySymbol], track: media[track], issueTagNumber: media[issueTagNumber], mimeType: media[mimeType], filePath: media[filePath], meps: media[meps] ?? 0)
                    array.append(data)
                }
            } catch{
                print(error)
            }
        }
        
        return array
    }
    
    func mediaDatatovideoData(mediaData: mediaData, completion: @escaping (videoData) -> Void) {

            if mediaData.mimeType == "video/mp4"{
                switch mediaData.mediaType {
                case "sjjm",
                     "thv",
                     "pk":
                      let urlpart1: String = "https://data.jw-api.org/mediator/v1/media-items/" + language! + "/pub-" + mediaData.mediaType! + "_" + String(mediaData.track!) + "_VIDEO"
                      let mediaID:Int = mediaData.mediaID
                      let urlmain = URL(string: urlpart1)
                      let type:String = mediaData.mediaType!
                      var title:String = ""
                      var preview:String = ""
                      var url:String = ""
                      var filePath: String = ""
                      var downloaded:Bool = false

                      URLSession.shared.dataTask(with: urlmain!, completionHandler: {(data, response, error) in
                          guard let data = data else { return }
                          do{
                              let json = try JSON(data: data)
                              title = json["media"][0]["title"].string ?? ""
                              preview = json["media"][0]["images"]["sqr"]["md"].string ?? ""
                              let list: Array<JSON> = json["media"][0]["files"].arrayValue
                              for index in 0 ..< list.count {
                                  let label = json["media"][0]["files"][index]["label"].string!
                                  let sub = json["media"][0]["files"][index]["subtitled"].bool ?? false
                                  if label == "720p" && sub == false {
                                      url = json["media"][0]["files"][index]["progressiveDownloadURL"].string!
                                  }
                              }
                              let convertURL = URL(string: url)
                              filePath = convertURL?.lastPathComponent ?? ""
                              let downloadUrl = FileManager.default.urls(for:.downloadsDirectory, in: .userDomainMask)[0]
                              let path = downloadUrl.appendingPathComponent(filePath)
                            print(path)
                              if FileManager.default.fileExists(atPath: path.path) {
                                  downloaded = true
                              }
                              else{
                                  downloaded = false
                              }
                              let output = videoData(mediaID: mediaID, type: type, title: title, preview: preview, url: url, filePath: filePath, downloaded: downloaded)
                              completion(output)
                          } catch {
                              print(error)
                          }

                          }).resume()
                    
                case "jwb",
                     "mwbv",
                     "jwban":
                    let issueRaw:String = String(mediaData.issueTagNumber)
                    let issueMain:String = issueRaw[0..<6]
                    let urlpart1: String = "https://data.jw-api.org/mediator/v1/media-items/" + language! + "/pub-" + mediaData.mediaType! + "_" + issueMain + "_" + String(mediaData.track!) + "_VIDEO"
                    let urlmain = URL(string: urlpart1)
                    let mediaID:Int = mediaData.mediaID
                    let type:String = mediaData.mediaType!
                    var title:String = ""
                    var preview:String = ""
                    var url:String = ""
                    var filePath: String = ""
                    var downloaded:Bool = false

                    URLSession.shared.dataTask(with: urlmain!, completionHandler: {(data, response, error) in
                        guard let data = data else { return }
                        do{
                            let json = try JSON(data: data)
                            title = json["media"][0]["title"].string ?? ""
                            preview = json["media"][0]["images"]["sqr"]["md"].string ?? ""
                            let list: Array<JSON> = json["media"][0]["files"].arrayValue
                            for index in 0 ..< list.count {
                                let label = json["media"][0]["files"][index]["label"].string!
                                let sub = json["media"][0]["files"][index]["subtitled"].bool ?? false
                                if label == "720p" && sub == false {
                                    url = json["media"][0]["files"][index]["progressiveDownloadURL"].string!
                                }
                            }
                            let convertURL = URL(string: url)
                            filePath = convertURL?.lastPathComponent ?? ""
                            let downloadUrl = FileManager.default.urls(for:.downloadsDirectory, in: .userDomainMask)[0]
                            let path = downloadUrl.appendingPathComponent(filePath)
                            if FileManager.default.fileExists(atPath: path.path) {
                                downloaded = true
                            }
                            else{
                                downloaded = false
                            }
                            let output = videoData(mediaID: mediaID, type: type, title: title, preview: preview, url: url, filePath: filePath, downloaded: downloaded)
                            completion(output)
                        } catch {
                            print(error)
                        }

                        }).resume()
                case "docid":
                    let issueMain: String = String(mediaData.issueTagNumber)
                    //let issueRaw:String = String(mediaData.issueTagNumber)
                    //let issueMain:String = issueRaw[0..<6]
                    let urlpart1: String = "https://data.jw-api.org/mediator/v1/media-items/" + language! + "/docid-" + issueMain + "_" + String(mediaData.track!) + "_VIDEO"
                    let urlmain = URL(string: urlpart1)
                    let mediaID:Int = mediaData.mediaID
                    let type:String = mediaData.mediaType!
                    var title:String = ""
                    var preview:String = ""
                    var url:String = ""
                    var filePath: String = ""
                    var downloaded:Bool = false

                    URLSession.shared.dataTask(with: urlmain!, completionHandler: {(data, response, error) in
                        guard let data = data else { return }
                        do{
                            let json = try JSON(data: data)
                            title = json["media"][0]["title"].string ?? ""
                            preview = json["media"][0]["images"]["sqr"]["md"].string ?? ""
                            let list: Array<JSON> = json["media"][0]["files"].arrayValue
                            for index in 0 ..< list.count {
                                let label = json["media"][0]["files"][index]["label"].string!
                                let sub = json["media"][0]["files"][index]["subtitled"].bool ?? false
                                if label == "720p" && sub == false {
                                    url = json["media"][0]["files"][index]["progressiveDownloadURL"].string!
                                }
                            }
                            let convertURL = URL(string: url)
                            filePath = convertURL?.lastPathComponent ?? ""
                            let downloadUrl = FileManager.default.urls(for:.downloadsDirectory, in: .userDomainMask)[0]
                            let path = downloadUrl.appendingPathComponent(filePath)
                            if FileManager.default.fileExists(atPath: path.path) {
                                downloaded = true
                            }
                            else{
                                downloaded = false
                            }
                            let output = videoData(mediaID: mediaID, type: type, title: title, preview: preview, url: url, filePath: filePath, downloaded: downloaded)
                            completion(output)
                        } catch {
                            print(error)
                        }

                        }).resume()
                default:
                    if mediaData.meps > 0 {
                        let meps = mediaData.meps
                        let urlpart1: String = "https://data.jw-api.org/mediator/v1/media-items/" + language! + "/docid-" + String(meps)
                        let urlpart2: String = "_" + String(mediaData.track!) + "_VIDEO"
                        let urlmain = URL(string: urlpart1 + urlpart2)
                        let mediaID:Int = mediaData.mediaID
                        var title:String = ""
                        var preview:String = ""
                        var url:String = ""
                        var filePath: String = ""
                        var downloaded:Bool = false

                        URLSession.shared.dataTask(with: urlmain!, completionHandler: {(data, response, error) in
                            guard let data = data else { return }
                            do{
                                let json = try JSON(data: data)
                                title = json["media"][0]["title"].string ?? ""
                                preview = json["media"][0]["images"]["sqr"]["md"].string ?? ""
                                let list: Array<JSON> = json["media"][0]["files"].arrayValue
                                for index in 0 ..< list.count {
                                    let label = json["media"][0]["files"][index]["label"].string!
                                    let sub = json["media"][0]["files"][index]["subtitled"].bool ?? false
                                    if label == "720p" && sub == false {
                                        url = json["media"][0]["files"][index]["progressiveDownloadURL"].string!
                                    }
                                }
                                let convertURL = URL(string: url)
                                filePath = convertURL?.lastPathComponent ?? ""
                                let downloadUrl = FileManager.default.urls(for:.downloadsDirectory, in: .userDomainMask)[0]
                                let path = downloadUrl.appendingPathComponent(filePath)
                                if FileManager.default.fileExists(atPath: path.path) {
                                    downloaded = true
                                }
                                else{
                                    downloaded = false
                                }
                                let output = videoData(mediaID: mediaID, type: "", title: title, preview: preview, url: url, filePath: filePath, downloaded: downloaded)
                                completion(output)
                            } catch {
                                print(error)
                            }

                            }).resume()
                    }
                    else{
                        let filePath: String = mediaData.filePath
                        let downloadUrl = FileManager.default.urls(for:.downloadsDirectory, in: .userDomainMask)[0]
                        let path = downloadUrl.appendingPathComponent(mediaData.filePath)
                        let title = path.lastPathComponent
                        let url:String = path.absoluteString
                        print(path.path)
                        if FileManager.default.fileExists(atPath: path.path) {
                            let output = videoData(mediaID: mediaData.mediaID, type: mediaData.mediaType ?? "", title: title, preview: "https://www.marinerschurch.org/wp-content/uploads/2020/02/placeholder.png", url: url, filePath: filePath,downloaded: true)
                            completion(output)
                        }
                        else{
                            print("media type '" + mediaData.mediaType! + "' not found")
                        }
                    }
                }
            }
        
            if mediaData.mimeType == "image/jpeg"{
                let downloadUrl = FileManager.default.urls(for:.downloadsDirectory, in: .userDomainMask)[0]
                let path = downloadUrl.appendingPathComponent(mediaData.filePath)
                let mediaID:Int = mediaData.mediaID
                let type:String = mediaData.mimeType
                let title:String = ""
                let preview:String = path.absoluteString
                let url:String = path.absoluteString
                let filePath: String = mediaData.filePath
                var downloaded:Bool = false
                if FileManager.default.fileExists(atPath: path.path) {
                    downloaded = true
                }
                else{
                    downloaded = false
                }
                if filePath.contains("univ_cnt") || filePath.contains("univ_lsr"){
                    let output = videoData(mediaID: mediaID, type: type, title: title, preview: preview, url: url, filePath: filePath,downloaded: downloaded)
                    completion(output)
                }
            }
    
        if mediaData.mimeType == "add"{
            let output = videoData(mediaID:100, type: "add", title: "", preview: "add", url: "", filePath: "", downloaded: true)
            completion(output)
        }
                

    }
    
    func getYearsText(completion: @escaping (String) -> Void) {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yy"
        let yy = dateFormatter.string(from: now)
        GetDailyText(issue: yy, language: "S"){ YearTextUrl in
            self.New(url: YearTextUrl){
                    do {
                        let attributedStringWithRtf: NSAttributedString = try NSAttributedString(url: self.suggestedFileName, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
                        completion(attributedStringWithRtf.string.slice(from: "Texto del año", to: "Programa")!)
                    } catch let error {
                        print("Got an error \(error)")
                    }
                }
            }
    }
    
    func GetDailyText(issue: String, language: String, completion: @escaping (String) -> Void){
        let url = URL(string: "https://pubmedia.jw-api.org/GETPUBMEDIALINKS?output=json&pub=es" + issue + "&fileformat=PDF%2CEPUB%2CJWPUB%2CRTF%2CTXT%2CBRL%2CBES%2CDAISY&alllangs=0&langwritten=" + language + "&txtCMSLang="  + language)
    
        var YearTextURL: String = ""
        
        
        URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            guard let data = data else { return }
            do{
                let json = try JSON(data: data)
                YearTextURL = json["files"][language]["RTF"][1]["file"]["url"].string!
                completion(YearTextURL)
            } catch {
                print(error)
            }
            
            }).resume()
    }
    
    
    
}
