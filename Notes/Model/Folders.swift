//
//  Folders.swift
//  Notes
//
//  Created by otet_tud on 1/21/20.
//  Copyright © 2020 otet_tud. All rights reserved.
//

import Foundation

class Folder : NSObject {
    private var fname : String
    private var notesNum : Int
    var notesList : [Note]
    
    internal init(fname: String, notesNum: Int, notesList: [Note]) {
        self.fname = fname
        self.notesNum = notesList.count
        self.notesList = notesList
    }
    
    func getFolderName() -> String {
        return self.fname
    }
    
    func getNumNotes() -> Int {
        self.setNumNotes(num: self.getNotesList().count)
        return self.notesList.count
    }
    
    func getNotesList() -> [Note] {
        return self.notesList
    }
    
    func setFolderName(fname: String) {
        self.fname = fname
    }
    
    func setNumNotes(num: Int) {
        self.notesNum = num
    }

    func setNotesList(notesList : [Note]) {
        self.notesList = notesList
    }
    
    func addNoteList(note: Note) {
        self.notesList.append(note)
        self.setNumNotes(num: self.getNotesList().count)
        print("DEBUG: Added new note!")
    }
    
}
