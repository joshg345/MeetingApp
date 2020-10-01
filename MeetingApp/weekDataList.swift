//
//  weekDataList.swift
//  MeetingApp
//
//  Created by Joshua on 28/03/2020.
//  Copyright © 2020 Josh. All rights reserved.
//

import SwiftUI

var array: [weekData] = []

class weekDataFunc{

    func populateArray(startDate: Int, endDate: Int, documentID: Int){
            let startDateString = String(startDate)
            let endDateString = String(endDate)
            //input date formatter
            let inputDateFormatter = DateFormatter()
            inputDateFormatter.locale = Locale(identifier: "en_US_POSIX")
            inputDateFormatter.dateFormat = "yyyyMMdd"
            //output date formatter
            let outputDateFormatter = DateFormatter()
            outputDateFormatter.dateFormat = "MMMM dd"
            //convert startDate with string
            let startInputDate = inputDateFormatter.date(from: startDateString)
            let startOutputDate = outputDateFormatter.string(from: startInputDate!)
            //convert endDate
            let endInputDate = inputDateFormatter.date(from: String(endDateString))
            let endOutputDate = outputDateFormatter.string(from: endInputDate!)
            //load array
            let data = weekData(startDate:startOutputDate, endDate: endOutputDate, documentID: documentID, custom: false)
            array.append(data)
    }
    
    func addCustom(name: String, documentID: Int){
        let data = weekData(documentID: documentID, custom: true, customName: name)
        array.append(data)
    }
    
    func getLastDocumentId() -> Int{
        return array[array.count - 1].documentID
    }
    
}

struct weekData: Identifiable {
    var id = UUID()
    var startDate: String?
    var endDate: String?
    var documentID: Int
    var custom: Bool
    var customName: String?
}

struct weekDataList: View {
    let weekDataF = weekDataFunc()
    @ObservedObject var MainViews = MainView()
    var body: some View {
        VStack {
            ForEach(0..<array.count, id: \.self) { index in
                VStack{
                    if array[index].custom {
                        Button(action: {self.MainViews.getMedia(documentId: array[index].documentID, nextDocumentId: array[index].documentID, startDate: "", endDate: "", custom: true)}) { Text(array[index].customName!)}
                        .buttonStyle(BorderlessButtonStyle())
                        .offset(x:0,y:20)
                    }
                    else{
                        if (index + 1 == array.count){
                            Button(action: {self.MainViews.getMedia(documentId: array[index].documentID, nextDocumentId: array[index].documentID, startDate: array[index].startDate!, endDate: array[index].endDate!, custom: false)}) { Text(array[index].startDate! + "-" + array[index].endDate!)}
                            .buttonStyle(BorderlessButtonStyle())
                            .offset(x:0,y:20)
                        }
                        else{
                            Button(action: {self.MainViews.getMedia(documentId: array[index].documentID, nextDocumentId: array[index + 1].documentID, startDate: array[index].startDate!, endDate: array[index].endDate!, custom: false)}) { Text(array[index].startDate! + "-" + array[index].endDate!)}
                                .buttonStyle(BorderlessButtonStyle())
                                .offset(x:0,y:20)
                        }
                    }
                }
            }
        }
        //.position(x:100,y:-100)
    }
}

struct weekDataList_Previews: PreviewProvider {
    static var previews: some View {
        weekDataList()
    }
}
