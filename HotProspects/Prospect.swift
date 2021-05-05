//
//  Prospect.swift
//  HotProspects
//
//  Created by Kristoffer Eriksson on 2021-05-02.
//


import SwiftUI

class Prospect: Identifiable, Codable{
    var id = UUID()
    var name = "anonymous"
    var emailAdress = ""
    var date = Date()
    fileprivate(set) var isContacted = false
}

class Prospects: ObservableObject {
    @Published private(set) var people: [Prospect]
    static let saveKey = "SavedData"
    
    init(){
        //Loading using User Defaults
        
//        if let data = UserDefaults.standard.data(forKey: Self.saveKey){
//            if let decoded = try? JSONDecoder().decode([Prospect].self, from: data){
//                self.people = decoded
//                return
//            }
//        }
        
        //Loading using disk, could not use internal func ?
        self.people = [Prospect]()
        if self.people.isEmpty {
            self.people = load(name: Self.saveKey)
        }
        
    }
    
   func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
        
    func load(name: String) -> [Prospect] {
        let url = getDocumentsDirectory().appendingPathComponent(name)
        if let data = try? Data(contentsOf: url) {
            if let decoded = try? JSONDecoder().decode([Prospect].self, from: data) {
                return decoded
            }
        }
        return []
    }
    
    private func save(){
        if let encoded = try? JSONEncoder().encode(people){
            //saving using userDefaults
            //UserDefaults.standard.set(encoded, forKey: Self.saveKey)
            
            //saving writing to disk
            do {
                let filename = getDocumentsDirectory().appendingPathComponent(Self.saveKey)
                //let data = try JSONEncoder().encode(self.people)
                try encoded.write(to: filename, options: [.atomicWrite, .completeFileProtection])
                print("saved data")
            } catch {
                print("Unable to save data")
            }
            
        }
    }
    
    func add(_ prospect: Prospect){
        people.append(prospect)
        save()
    }
    
    func toggle(_ prospect: Prospect){
        objectWillChange.send()
        prospect.isContacted.toggle()
        save()
    }
}
