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
        self.notesNum = notesNum
        self.notesList = notesList
    }
    
    func getFolderName() -> String {
        return self.fname
    }
    
    func getNumNotes() -> Int {
        return self.notesNum
    }
    
    func getNotesList() -> [Note] {
        return [Note]()//self.notesList
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
    }
    
}
