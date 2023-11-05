//
//  NotesInfo.swift
//  Notes
//
//  Created by Vyacheslav on 19.10.2023.
//

import UIKit
import CoreData

class NotesInfo: UIViewController {
    
    @IBOutlet weak var titleNotes: UITextView!
    @IBOutlet weak var notesText: UITextView!
    
    var selectedCell = ""
    var selectedID : UUID?
    var mainNote = ""
    
    enum OperationType: String {
        
        case updateItem
        case deleteItem
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        readFromBase()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        writeToBase()
    }
}

// MARK: - NotesInfo + Private methods
private extension NotesInfo {
    
    func setup() {
        titleNotes.delegate = self
        notesText.delegate = self
    }
    
    func readFromBase() {
        if selectedCell != "" {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
            fetchRequest.returnsObjectsAsFaults = false
            
            let idString = selectedID!.uuidString
            fetchRequest.predicate = NSPredicate(format: "idCell = %@", idString)
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let noteTittle = result.value(forKey: "titleText") as? String {
                            titleNotes.text = noteTittle
                        }
                        if let mainNote = result.value(forKey: "mainNotes") as? String {
                            notesText.text = mainNote
                        }
                    }
                }
            } catch {
                print("cant read db")
            }
        } else if selectedCell == "" && mainNote != "" {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
            fetchRequest.returnsObjectsAsFaults = false
            
            let idString = selectedID!.uuidString
            fetchRequest.predicate = NSPredicate(format: "idCell = %@", idString)
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        titleNotes.text = ""
                        if let note = result.value(forKey: "mainNotes") as? String {
                            notesText.text = note
                        }
                    }
                }
            } catch {
                print("can't (0)")
            }
        } else {
            titleNotes.text = ""
            notesText.text = ""
            notesText.isEditable = false
        }
    }
    
    func writeToBase() {
        if titleNotes.text != "" && selectedCell == "" && mainNote == "" {
            writeToEmptyBase()
        } else if titleNotes.text != "" && selectedCell != "" {
            updateBaseItem(operationType: .updateItem)
        } else if selectedCell == "" && notesText.text != "" && titleNotes.text != ""{
            updateBaseItem(operationType: .updateItem)
        } else if titleNotes.text == "" && notesText.text != "" && selectedCell != "" {
            updateBaseItem(operationType: .updateItem)
        }
        if titleNotes.text == "" && notesText.text == "" && selectedCell != "" && (mainNote != "" || mainNote == "") {
            updateBaseItem(operationType: .deleteItem)
        }
    }
    
    func writeToEmptyBase() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let newNote = NSEntityDescription.insertNewObject(forEntityName: "Notes", into: context)
        
        newNote.setValue(titleNotes.text!, forKey: "titleText")
        newNote.setValue(notesText.text!, forKey: "mainNotes")
        newNote.setValue(UUID(), forKey: "idCell")
        do {
            try context.save()
        } catch {
            print("can't save (1)")
        }
        NotificationCenter.default.post(name: NSNotification.Name("dataSaved"), object: nil)
    }
    
    func updateBaseItem(operationType: OperationType) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
        
        let idString = selectedID?.uuidString
        fetchRequest.predicate = NSPredicate(format: "idCell = %@", idString!)
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    switch operationType {
                    case .updateItem:
                        result.setValue(titleNotes.text!, forKey: "titleText")
                        result.setValue(notesText.text!, forKey: "mainNotes")
                    case .deleteItem:
                        context.delete(result)
                    }
                    do {
                        try context.save()
                    } catch {
                        print("no")
                    }
                }
            }
            
        } catch {
            print("can't save (2)")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("dataSaved"), object: nil)
    }
}

// MARK: - NotesInfo + UITextViewDelegate
extension NotesInfo: UITextViewDelegate {
    
    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        let text = (textView.text ?? "") as NSString
        let newText = text.replacingCharacters(in: range, with: text as String)
        if !newText.isEmpty {
            notesText.isEditable = true
        } else if titleNotes.text.isEmpty{
            notesText.isEditable = false
        }
        return true
    }
}
