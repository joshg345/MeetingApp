//
//  ExtendedScreenView.swift
//  MeetingApp
//
//  Created by Joshua on 13/04/2020.
//  Copyright © 2020 Josh. All rights reserved.
//

import SwiftUI
import AVKit
import AVFoundation
import NotificationCenter
import SDWebImageSwiftUI
import SDWebImage

//let JW = JWPUB()

struct ExtendedScreenFunc{
    
    func populateText(completion: @escaping (String) -> Void){
        JW.getYearsText(){ output in
            completion(output)
        }
    }
    
}

struct ExtendedScreenView: View {
    @ObservedObject var globalScrollTitle: ScrollTitle = ScrollTitle.sharedInstance
    @ObservedObject var globalShowVideo: ShowVideoVars = ShowVideoVars.sharedInstance
    @State var placeHolderText = ""
    //@State var showVideo: Bool = false
    let test = ExtendedScreenFunc()
    var body: some View {
        ZStack{
            Text(placeHolderText)
            .onAppear(){
                self.test.populateText(){ output in
                    self.placeHolderText = output
            }
        }
            if globalShowVideo.showVideo == true{
                PlayerView(player: $globalScrollTitle.videoItem.player)
            }
            if globalShowVideo.showImage == true{
                Rectangle()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    //.background(Color.black)
                    .foregroundColor(Color.black)
                WebImage(url: URL(string: globalShowVideo.imageURL))
                .resizable()
                .scaledToFit()
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .font(.custom("SourceSansPro-Regular.otf", size: 50))
        .background(Color.black)
    }
    
}

struct ExtendedScreenView_Previews: PreviewProvider {
    static var previews: some View {
        ExtendedScreenView()
    }
}

class VideoItem: ObservableObject {
    @ObservedObject var globalShowVideo: ShowVideoVars = ShowVideoVars.sharedInstance
    @Published var player: AVPlayer = AVPlayer()
    @Published var playerItem: AVPlayerItem?

    func open(_ url: URL) {
        globalShowVideo.showImage = false
        globalShowVideo.showVideo = true
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        self.playerItem = playerItem
        player.replaceCurrentItem(with: playerItem)
        player.play()
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)

    }
    
    func stop(){
        player.pause()
        globalShowVideo.showVideo = false
        globalShowVideo.currentVideo = ""
    }
    
    @objc func playerDidFinishPlaying(note: NSNotification) {
        globalShowVideo.showVideo = false
        globalShowVideo.currentVideo = ""
    }
    
    func showImage(image: String){
        player.pause()
        globalShowVideo.showVideo = false
        globalShowVideo.imageURL = image
        globalShowVideo.showImage = true
    }
    
}

struct PlayerView: NSViewRepresentable {
    @Binding var player: AVPlayer

    func updateNSView(_ NSView: NSView, context: NSViewRepresentableContext<PlayerView>) {
        guard let view = NSView as? AVPlayerView else {
            debugPrint("unexpected view")
            return
        }

        view.player = player
    }

    func makeNSView(context: Context) -> NSView {
        return AVPlayerView(frame: .zero)
    }
}


