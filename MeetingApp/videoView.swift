//
//  videoView.swift
//  MeetingApp
//
//  Created by Joshua on 08/04/2020.
//  Copyright © 2020 Josh. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import SDWebImage
import AVFoundation


var downloader = download()
var complete: Bool = false
var downloadingBlock: Bool = false

struct videoData: Identifiable {
    var id = UUID()
    var mediaID:Int = 0
    var type:String = ""
    var title:String = ""
    var preview:String = ""
    var url:String = ""
    var filePath: String = ""
    var downloaded:Bool = false
}

struct mediaData: Identifiable{
    var id = UUID()
    var mediaID:Int
    var mediaType:String? = ""
    var track:Int?
    var issueTagNumber:Int
    var mimeType:String = ""
    var filePath:String = ""
    var meps:Int
}

struct videoView: View {
    @ObservedObject var globalShowVideo: ShowVideoVars = ShowVideoVars.sharedInstance
    @ObservedObject var globalScrollTitle: ScrollTitle = ScrollTitle.sharedInstance
    @State var downloading:Bool = false
    @State var video:videoData = videoData()
    @State var imageShow:Bool = false
    let downloadUrl = FileManager.default.urls(for:.downloadsDirectory, in: .userDomainMask)[0]
    var body: some View {
        VStack{
            Text(video.title)
            .font(.custom("SourceSansPro-Regular.otf", size: 10))
            .frame(width: 200)
            .lineLimit(1)
            ZStack(alignment: .bottomLeading){
                if video.preview != ""{
                    WebImage(url: URL(string: video.preview))
                    .resizable()
                    .frame(width: 200, height: 100, alignment: .center)
                    .onTapGesture {
                        self.imageShow = false
                        if downloadingBlock == false{
                                if self.video.type == "image/jpeg"{
                                    self.imageShow = true
                                    let downloadUrl = FileManager.default.urls(for:.downloadsDirectory, in: .userDomainMask)[0]
                                    let path = downloadUrl.appendingPathComponent(self.video.filePath)
                                    self.globalScrollTitle.videoItem.showImage(image: path.absoluteString)
                                }
                                else{
                                    if self.video.downloaded == false{
                                        downloadingBlock = true
                                        self.downloading = true
                                        self.video.downloaded = true
                                        downloader.download(url: self.video.url, fileName: self.video.filePath) {
                                            self.downloading = false
                                            self.globalScrollTitle.mainprogress = 0
                                            downloadingBlock = false
                                        }
                                    }
                                    else{
                                        if self.globalShowVideo.currentVideo == "" || self.globalShowVideo.currentVideo != self.video.title{
                                            self.imageShow = false
                                            let downloadUrl = FileManager.default.urls(for:.downloadsDirectory, in: .userDomainMask)[0]
                                            let path = downloadUrl.appendingPathComponent(self.video.filePath)
                                            self.globalShowVideo.currentVideo = self.video.title
                                            self.globalScrollTitle.videoItem.open(path)
                                        }
                                        else if self.globalShowVideo.currentVideo == self.video.title{
                                            self.globalScrollTitle.videoItem.stop()
                                        }
                                    }
                                }
                        }
                    }
                }
                else{
                    Image("notavailable")
                    .resizable()
                    .frame(width:200, height:100)
                }
                if self.video.type == "add"{
                    Image("add-button")
                    .resizable()
                    .frame(width:200, height:100)
                    .onTapGesture {
                        self.globalScrollTitle.showAdd = true
                    }
                }
                if imageShow == true {
                    Image("remove")
                    .resizable()
                    .frame(width:64, height:64)
                        .onTapGesture {
                            self.imageShow = false
                            self.globalShowVideo.showImage = false
                        }
                }
                if downloading == true{
                    ProgressBar(value: $globalScrollTitle.mainprogress)
                }
                if video.downloaded == false{
                    Image("download")
                    .resizable()
                    .frame(width:25, height:25)
                }
            }
        }
    }
}

struct videoView_Previews: PreviewProvider {
    static var previews: some View {
        videoView()
    }
}

class download/*: NSObject, URLSessionDelegate, URLSessionDownloadDelegate*/{
    
    @ObservedObject var globalScrollTitle: ScrollTitle = ScrollTitle.sharedInstance
    var observation: NSKeyValueObservation?
    
    func download(url: String, fileName: String, completion: @escaping () -> Void) {
        let myUrl = URL(string: url)
        let request = URLRequest(url:myUrl!)
        let config = URLSessionConfiguration.default
        let operationQueue = OperationQueue()
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: operationQueue)
        
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
                let fileURL = documentFolderURL.appendingPathComponent(fileName)
                try data!.write(to: fileURL)

                DispatchQueue.main.async {

                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        print("file present!") // Confirm that the file is here!
                    }
                }
                
            } catch  {
                print("error writing file \(error)")
            }
        }
        
        observation = task.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async(execute: {
                self.globalScrollTitle.mainprogress = CGFloat(progress.fractionCompleted)
            })
            if progress.fractionCompleted == 1 {
                self.globalScrollTitle.mainprogress = 0
                completion()
            }
        }
        
        task.resume()
    }
}

struct ProgressBar: View {
    @Binding var value:CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .trailing) {
                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                        .opacity(0.1)
                    Rectangle()
                        .frame(minWidth: 0, idealWidth:self.getProgressBarWidth(geometry: geometry),
                               maxWidth: self.getProgressBarWidth(geometry: geometry))
                        .opacity(0.5)
                        .background(Color(red: 0.8, green: 0.3, blue: 1.5))
                        .animation(.default)
                }
                .frame(height:5)
            }.frame(height:5)
        }
    }
    
    func getProgressBarWidth(geometry:GeometryProxy) -> CGFloat {
        //let frame = geometry.frame(in: .global)
        //return frame.size.width * value
         return 200 * value
    }
    

}
