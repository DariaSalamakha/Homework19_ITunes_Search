
import UIKit
// MARK: - StoreItemListTableViewController
@MainActor
class StoreItemListTableViewController: UITableViewController {
    
    // MARK: - Outlets
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var filterSegmentedControl: UISegmentedControl!
    
    // MARK: - Outlets
    var items = [StoreItem]()
    var imageLoadTasks: [IndexPath: Task<Void, Never>] = [:]
    let queryOptions = ["movie", "music", "software", "ebook"]
    let storeItemController = StoreItemController()
   
    // MARK: - Live circle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Methods
    func fetchMatchingItems() {
        
        self.items = []
        self.tableView.reloadData()
        
        let searchTerm = searchBar.text ?? ""
        let mediaType = queryOptions[filterSegmentedControl.selectedSegmentIndex]
        
        if !searchTerm.isEmpty {
            
            let query = [
                "term": searchTerm,
                "media": mediaType,
                "lang": "en_us"
            ]
            
            Task {
                do {
                    let storeItems = try await storeItemController.fetchItems(matching: query)
                    self.items = storeItems
                    self.tableView.reloadData()
                    }
                catch let error {
                        print(error)
                    }
                }
            }
        }
    
    func configure(cell: ItemCell, forItemAt indexPath: IndexPath) {
        
        let item = items[indexPath.row]
        cell.name = item.name
        cell.artist = item.artist
       
        imageLoadTasks[indexPath] = Task {
            do {
                let image = try await storeItemController.fetchImage(artworkURL: item.artworkURL)
                cell.artworkImage = image
                self.tableView.reloadData()
            }
            catch let error {
                print(error)
            }
        }
        imageLoadTasks[indexPath] = nil
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Item", for: indexPath) as! ItemCell
        configure(cell: cell, forItemAt: indexPath)

        return cell
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // cancel the image fetching task if we no longer need it
        imageLoadTasks[indexPath]?.cancel()
    }
    
    // MARK: - Actions
    @IBAction func filterOptionUpdated(_ sender: UISegmentedControl) {
        fetchMatchingItems()
    }
}

// MARK: - Extension
extension StoreItemListTableViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        fetchMatchingItems()
        searchBar.resignFirstResponder()
    }
}

