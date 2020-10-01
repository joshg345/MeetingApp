//
//  languageList.swift
//  MeetingApp
//
//  Created by Joshua on 22/04/2020.
//  Copyright © 2020 Josh. All rights reserved.
//

import SwiftUI
import SwiftyJSON

var languageArray: [languageJW] = []
var resultsArray:[languageJW] = []
var languageF = languageFunc()
var window2:NSWindow!


class languageFunc {
    @ObservedObject var globalScrollTitle: ScrollTitle = ScrollTitle.sharedInstance
    func populateArray(){
        
        let urlmain = URL(string: "https://www.jw.org/en/languages/")

        URLSession.shared.dataTask(with: urlmain!, completionHandler: {(data, response, error) in
            guard let data = data else { return }
            do{
                self.globalScrollTitle.languagesDownloading = true
                let json = try JSON(data: data)
                let list: Array<JSON> = json["languages"].arrayValue
                for index in 0 ..< list.count {
                    let languageName = json["languages"][index]["name"].string!
                    let langcode = json["languages"][index]["langcode"].string!
                    let language = languageJW(languageName: languageName, languageCode: langcode)
                    languageArray.append(language)
                    DispatchQueue.main.async(execute: {
                        let value = Float(index) / Float(list.count)
                        print(value)
                        self.globalScrollTitle.loadingprogress = CGFloat(value)
                    })
                    if index + 1 == list.count {
                        self.globalScrollTitle.languagesDownloading = false
                        print(self.globalScrollTitle.languagesDownloading)
                    }
                }
                //self.globalScrollTitle.showLanguage = true
            } catch {
                print(error)
            }

            }).resume()
    }
    
    func showWindow(){
        let loading = languageList()
        
        window2 = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window2.center()
        window2.contentView = NSHostingView(rootView: loading)
        window2.makeKeyAndOrderFront(nil)
    }
    
    func updateLanguage(languageName: String, languageCode: String) {
        //let language = languageJW(languageName: languageName, languageCode: languageCode)
        UserDefaults.standard.set(languageCode, forKey: "savedLanguage")
    }
}

struct languageJW: Identifiable, Hashable{
    var id = UUID()
    var languageName: String
    var languageCode: String
}

struct languageList: View {
    @ObservedObject var globalScrollTitle: ScrollTitle = ScrollTitle.sharedInstance
    @State var location: String = ""
    @State var updateResults: Int = 0
    @State var empty: Bool = false
    var languageF = languageFunc()
    var body: some View {
            let binding = Binding<String>(get: {
                self.location
            }, set: {
                self.location = $0
                resultsArray.removeAll()
                
                if self.location.isEmpty {
                    self.empty = true
                }
                else {
                    self.empty = false
                    for language in languageArray {
                        if (language.languageName.range(of: self.location, options: .caseInsensitive) != nil) || self.location == language.languageName{
                            let data = languageJW( languageName: language.languageName, languageCode: language.languageCode)
                            resultsArray.append(data)
                        }
                    }
                }
                if self.globalScrollTitle.languagesDownloading == false {
                    if self.updateResults == 0 {
                        self.updateResults = 1
                    }
                    else {
                        self.updateResults = 0
                    }
                }
            })

            return VStack {
                    if self.globalScrollTitle.languagesDownloading == true{
                        Text("Loading Languages...")
                        ProgressBar(value: $globalScrollTitle.loadingprogress)
                            .padding(50)
                    }
                    else {
                        Text("Languages")
                        TextField("Search for Language", text: binding, onEditingChanged: { (changed) in print("you finished typing")})

                        VStack{
                                List {
                                        if empty == false {
                                            if updateResults > 0 {
                                                ForEach(resultsArray, id: \.self) { language in
                                                    Text(language.languageName)
                                                        .onTapGesture {
                                                            self.languageF.updateLanguage(languageName: language.languageName, languageCode: language.languageCode)
                                                            print("language set to: " + UserDefaults.standard.string(forKey: "savedLanguage")!)
                                                            window2.close()
                                                    }
                                                }
                                            }
                                        else{
                                            ForEach(languageArray, id: \.self) { language in
                                                Text(language.languageName)
                                                    .onTapGesture {
                                                        self.languageF.updateLanguage(languageName: language.languageName, languageCode: language.languageCode)
                                                        print("language set to: " + UserDefaults.standard.string(forKey: "savedLanguage")!)
                                                        window2.close()
                                                }
                                            }
                                        }
                                        }
                                }
                        }
                    }
            }

        }
//        VStack(){
//            MenuButton(label: Text("Select Language...")) {
//                ForEach(0..<languageArray.count) { index in
//                    Button(action: {languageF.updateLanguage(languageName: languageArray[index].languageName, languageCode: languageArray[index].languageCode)}) { Text(languageArray[index].languageName)}
//                    //.offset(x:0,y:20)
//                }
//            }
//        }
}

struct languageList_Previews: PreviewProvider {
    static var previews: some View {
        languageList()
    }
}
