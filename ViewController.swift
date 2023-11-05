//
//  ViewController.swift
//  Notes
//
//  Created by Vyacheslav on 19.10.2023.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    @IBOutlet private weak var notesCells: UITableView!
    
    @IBOutlet private weak var countOfNotes: UILabel!
    
    var namesCellsArray = [String]()
    var idCellsArray = [UUID]()
    var notesArray = [String]()
    var flagsArrayForCells = [Bool]()
    
    var chosenCell = ""
    var chosenId : UUID?
    var retakeMainNote = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(uploadData),
                                               name: NSNotification.Name(rawValue: "dataSaved"),
                                               object: nil)
        uploadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showNote" {
            let destinationVC = segue.destination as! NotesInfo
            destinationVC.selectedCell = chosenCell
            destinationVC.selectedID = chosenId
            destinationVC.mainNote = retakeMainNote
        }
    }
    
}

// MARK: - ViewController + UITableViewDelegate
extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenCell = namesCellsArray[indexPath.row]
        chosenId = idCellsArray[indexPath.row]
        retakeMainNote = notesArray[indexPath.row]
        performSegue(withIdentifier: "showNote", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var counter : Int = 0
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
        
        let pinAction = UIContextualAction(style: .normal, title: "Закрепить") { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            let pinTittle = self.namesCellsArray[indexPath.row]
            let pinNote = self.notesArray[indexPath.row]
            
            self.namesCellsArray.remove(at: indexPath.row)
            self.notesArray.remove(at: indexPath.row)
            self.flagsArrayForCells.remove(at: indexPath.row)
            
            self.namesCellsArray.insert(pinTittle, at: 0)
            self.notesArray.insert(pinNote, at: 0)
            self.flagsArrayForCells.insert(true, at: 0)
            
            self.notesCells.reloadData()
            
            completionHandler(true)
        }
        
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    result.setValue(self.namesCellsArray[counter], forKey: "titleText")
                    result.setValue(self.notesArray[counter], forKey: "mainNotes")
                    do {
                        try context.save()
                    } catch {
                        print ("can't (90)")
                    }
                    counter += 1
                }
            }
        } catch {
            print("no (10)")
        }
        
        pinAction.backgroundColor = .blue
        
        let unPinAction = UIContextualAction(style: .normal, title: "Открепить") { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            self.flagsArrayForCells[indexPath.row] = false
            self.notesCells.reloadData()
            completionHandler(true)
        }
        
        unPinAction.backgroundColor = .red
        return UISwipeActionsConfiguration(actions: [pinAction, unPinAction])
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
            
            let idString = idCellsArray[indexPath.row].uuidString
            fetchRequest.predicate = NSPredicate(format: "idCell = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let id = result.value(forKey: "idCell") as? UUID {
                            if id == idCellsArray[indexPath.row] {
                                context.delete(result)
                                namesCellsArray.remove(at: indexPath.row)
                                idCellsArray.remove(at: indexPath.row)
                                if namesCellsArray.count == 0 {
                                    countOfNotes.text = "Нет Заметок"
                                } else if namesCellsArray.count == 1 {
                                    countOfNotes.text = "\(namesCellsArray.count) Заметка"
                                } else if namesCellsArray.count >= 2 && namesCellsArray.count <= 4 {
                                    countOfNotes.text = "\(namesCellsArray.count) Заметки"
                                } else {
                                    countOfNotes.text = "\(namesCellsArray.count) Заметок"
                                }
                                self.notesCells.reloadData()
                                do {
                                    try context.save()
                                } catch {
                                    print("deleting is failed")
                                }
                            }
                        }
                    }
                }
            } catch {
                print("error to read db")
            }
        }
    }
}

// MARK: - ViewController + UITableViewDataSource
extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return namesCellsArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        var context = cell.defaultContentConfiguration()
        
        if namesCellsArray[indexPath.row] != "" && notesArray[indexPath.row] != "" {
            context.text = namesCellsArray[indexPath.row]
            context.secondaryText = notesArray[indexPath.row]
        } else if namesCellsArray[indexPath.row] == "" && notesArray[indexPath.row] != "" {
            context.text = notesArray[indexPath.row]
            context.secondaryText = "Нет дополнительного текста"
        } else if namesCellsArray[indexPath.row] != "" && notesArray[indexPath.row] == "" {
            context.text = namesCellsArray[indexPath.row]
            context.secondaryText = "Нет дополнительного текста"
        }
        
        if flagsArrayForCells[indexPath.row] {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        cell.contentConfiguration = context
        
        return cell
    }
}

// MARK: - Private extension
private extension ViewController {
    
    func setup() {
        notesCells.delegate = self
        notesCells.dataSource = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonItem.SystemItem.add,
            target: self,
            action: #selector(createNote)
        )
        
        notesCells.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    func clearBase() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
        
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    context.delete(result)
                    
                    do {
                        try context.save()
                    } catch {}
                }
            }
        } catch {}
    }
}

// MARK: - Actions
private extension ViewController {
    
    @objc
    func createNote() {
        chosenCell = ""
        retakeMainNote = ""
        performSegue(withIdentifier: "showNote", sender: nil)
    }
    
    @objc
    func uploadData() {
        namesCellsArray.removeAll(keepingCapacity: false)
        idCellsArray.removeAll(keepingCapacity: false)
        notesArray.removeAll(keepingCapacity: false)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    if let titleText = result.value(forKey: "titleText") as? String {
                        self.namesCellsArray.insert(titleText, at: 0)
                    }
                    if let mainNote = result.value(forKey: "mainNotes") as? String {
                        self.notesArray.insert(mainNote, at: 0)
                    }
                    if let idCell = result.value(forKey: "idCell") as? UUID {
                        self.idCellsArray.insert(idCell, at: 0)
                    }
                    
                    self.notesCells.reloadData()
                }
            }
        } catch {
            print("failed to upload data")
        }
        
        flagsArrayForCells = Array(repeating: false, count: namesCellsArray.count)
        
        if namesCellsArray.count == 0 {
            countOfNotes.text = "Нет Заметок"
        } else if namesCellsArray.count == 1 {
            countOfNotes.text = "\(namesCellsArray.count) Заметка"
        } else if namesCellsArray.count >= 2 && namesCellsArray.count <= 4 {
            countOfNotes.text = "\(namesCellsArray.count) Заметки"
        } else {
            countOfNotes.text = "\(namesCellsArray.count) Заметок"
        }
    }
}
