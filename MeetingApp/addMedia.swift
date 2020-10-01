//
//  addMedia.swift
//  MeetingApp
//
//  Created by Joshua on 27/05/2020.
//  Copyright © 2020 Josh. All rights reserved.
//

import SwiftUI


class addMediaFunc{
    let JW = JWPUB()
    @ObservedObject var globalScrollTitle: ScrollTitle = ScrollTitle.sharedInstance

    func addMedia(type: String, title: String, preview: String, url: String, filePath: String, keySymbol: String, track: String, issue: String){
        JW.insert_DocumentMultimedia()
        globalScrollTitle.showAdd = false
    }
}

struct addMedia: View {
    var addMediaF = addMediaFunc()
    @ObservedObject var MainViews = MainView()
    @Binding var title: String
    @Binding var type: String
    @Binding var preview: String
    @Binding var url: String
    @Binding var filePath: String
    @Binding var keySymbol: String
    @Binding var track: String
    @Binding var issue: String
    var body: some View {
        Form {
            MenuButton(label: Text("Type")){
                Button(action: {self.type = "image/jpeg"}) {Text("image/jpeg")}
                Button(action: {self.type = "video/mp4"}) {Text("video/mp4")}
            }
            TextField("Title", text: $title)
            TextField("Preview (Preview Image)", text: $preview)
            TextField("URL (Non-downloaded media)", text: $url)
            TextField("File Path (Downloaded media)", text: $filePath)
            TextField("KeySymbol", text: $keySymbol)
            TextField("Track", text: $track)
            TextField("Issue", text: $issue)
            Button(action: {self.addMediaF.addMedia(type: self.type, title: self.title, preview: self.preview, url: self.url, filePath: self.filePath, keySymbol: self.keySymbol, track: self.track, issue: self.issue)}) {
            Text("Add")
            }
        }
        .frame(width: 200)
    }
}

struct addMedia_Previews: PreviewProvider {
    static var previews: some View {
        addMedia(title: .constant(""), type: .constant(""), preview: .constant(""), url: .constant(""), filePath: .constant(""), keySymbol: .constant(""), track: .constant(""), issue: .constant(""))
    }
}
