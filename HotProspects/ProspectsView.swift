//
//  ProspectsView.swift
//  HotProspects
//
//  Created by Kristoffer Eriksson on 2021-05-02.
//

import SwiftUI
import CodeScanner
import UserNotifications

struct ProspectsView: View {
    
    enum FilterType{
        case none, contacted, uncontacted
    }
    
    enum FilterStyle{
        //add ascending and descending
        case name, date, dateDesc
    }
    
    let filter: FilterType
    @State private var filterStyle: FilterStyle = .date
    @State private var isShowingFilterSort = false
    
    var title: String {
        switch filter {
        case .none:
            return "Everyone"
        case .contacted:
            return "Contacted People"
        case .uncontacted:
            return "Uncontacted People"
        }
    }
    
    var filteredProspects: [Prospect]{
        
        if filterStyle == .name {
            switch filter {
            case .none:
                return prospects.people.sorted {$0.name < $1.name}
            case .contacted:
                return prospects.people.filter {$0.isContacted}.sorted {$0.name < $1.name}
            case .uncontacted:
                return prospects.people.filter {!$0.isContacted}.sorted {$0.name < $1.name}
            }
        } else if filterStyle == .dateDesc{
            switch filter {
            case .none:
                return prospects.people.sorted {$0.date > $1.date}
            case .contacted:
                return prospects.people.filter {$0.isContacted}.sorted {$0.date > $1.date}
            case .uncontacted:
                return prospects.people.filter {!$0.isContacted}.sorted {$0.date > $1.date}
            }
        } else {
            switch filter {
            case .none:
                return prospects.people.sorted {$0.date < $1.date}
            case .contacted:
                return prospects.people.filter {$0.isContacted}.sorted {$0.date < $1.date}
            case .uncontacted:
                return prospects.people.filter {!$0.isContacted}.sorted {$0.date < $1.date}
            }
        }
        
        
    }
    
    @EnvironmentObject var prospects: Prospects
    
    @State private var isShowingScanner = false
    
    var body: some View {
        NavigationView{
            List {
                ForEach(filteredProspects){ prospect in
                    HStack {
                        VStack(alignment: .leading){
                            Text(prospect.name)
                                .font(.headline)
                            Text(prospect.emailAdress)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if filter == .none {
                            switch prospect.isContacted{
                            case true:
                                Image(systemName: "checkmark.circle")
                            default:
                                Image(systemName: "cross.circle")
                            }
                        }
                    }
                    .contextMenu{
                        Button(prospect.isContacted ? "Mark uncontacted" : "Mark contacted"){
                            self.prospects.toggle(prospect)
                        }
                        
                        if !prospect.isContacted{
                            Button("remind me"){
                                self.addNotification(for: prospect)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarItems(leading: Button(action: {
                self.isShowingFilterSort = true
            }) {
                Text("Sort Order")
            },trailing: Button(action: {
                self.isShowingScanner = true
            }) {
                Image(systemName: "qrcode.viewfinder")
                Text("Scan")
                }
            )
            .sheet(isPresented: $isShowingScanner){
                CodeScannerView(codeTypes: [.qr], simulatedData: "JimiHendrix\njimi@loolapaloza.com", completion: self.handleScan)
            }
            .actionSheet(isPresented: $isShowingFilterSort){
                ActionSheet(title: Text("Sort Contacts"), message: Text(""), buttons: [
                    .default(Text("Name")) { self.filterStyle = .name},
                    .default(Text("Date Descending")) { self.filterStyle = .dateDesc},
                    .default(Text("Date")) { self.filterStyle = .date},
                    .cancel(),
                    ]
                )
            }
        }
    }
    
    func handleScan(result: Result<String, CodeScannerView.ScanError>){
        self.isShowingScanner = false
        
        switch result{
        case .success(let code):
            let details = code.components(separatedBy: "\n")
            guard details.count == 2 else {return}
            
            let person = Prospect()
            person.name = details[0]
            person.emailAdress = details[1]
            person.date = Date()
            self.prospects.add(person)
        
        case .failure(let error):
            print("scanning failed")
        }
    }
    
    func addNotification(for prospect: Prospect){
        let center = UNUserNotificationCenter.current()
        
        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = "Email \(prospect.emailAdress)"
            content.sound  = UNNotificationSound.default
            
            //var dateComponents = DateComponents()
            //dateComponents.hour = 9
            
            //let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats:false)
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
            
        }
        
        center.getNotificationSettings{ settings in
            if settings.authorizationStatus == .authorized {
                addRequest()
            } else {
                center.requestAuthorization(options: [.alert, .badge, .sound]){ success, error in
                    if success {
                        addRequest()
                    } else {
                        print("Error time")
                    }
                }
            }
        }
    }
}

struct ProspectsView_Previews: PreviewProvider {
    static var previews: some View {
        ProspectsView(filter: .none)
    }
}
