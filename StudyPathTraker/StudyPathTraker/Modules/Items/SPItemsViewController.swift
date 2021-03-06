//
//  SPItemsViewController.swift
//  StudyPathTraker
//
//  Created by Rafael Lopez on 5/31/18.
//  Copyright © 2018 Jerti. All rights reserved.
//

import UIKit

class SPItemsViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet private var itemsTableViewDelegate: SPCommonTableViewDelegate! {
        didSet {
            itemsTableViewDelegate.selectedIndex = { [weak self] index in
                self?.selectedItem = self?.items?[index]
                self?.performSegue(withIdentifier: Segues.ItemsSegues.showDetail.rawValue, sender: nil)
            }
        }
    }
    
    // MARK: - Properties

    var dataSource: SPCommonTableViewDataSource<Item, SPItemTableViewCell>?
    private var refreshControl = UIRefreshControl()
    var items: [Item]? {
        didSet {
            if let settedItems = items {
                setItems(settedItems)
            }
        }
    }
    private let cellConfiguration = SPCommonCellConfiguration(identifier: "ItemCellIdentifier", height: 130.0)
    private var selectedItem: Item?
    var category: CategoryItem?
    var itemPresenter: SPItemPresenter = SPItemPresenter()

    // MARK: - View Configuration

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Readings"
        view.backgroundColor = .mainBackground
        itemPresenter.delegate = self
        configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getItems()
        selectedItem = nil
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detailViewController = segue.destination  as? SPDetailViewController {
            detailViewController.item = selectedItem
        }

        if let newItemViewController = segue.destination  as? SPNewItemViewController {
            guard let currentCategory = category else {
                return
            }
            if let itemToUpdate = selectedItem {
                newItemViewController.item = itemToUpdate
                newItemViewController.isToEdit = true
            }
            newItemViewController.category = currentCategory
        }
    }

    // MARK: - Functions

    @objc private func configureTableView() {
        tableView.backgroundColor = .mainBackground
        tableView.rowHeight = cellConfiguration.height
        refreshControl.attributedTitle = NSAttributedString(string: "Loading readings")
        refreshControl.addTarget(self, action: #selector(getItems), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl)
    }

    func setItems(_ items: [Item]) {
        dataSource = SPCommonTableViewDataSource<Item, SPItemTableViewCell>(data: items, reuseIdentifier: cellConfiguration.identifier, deleteAllowed: true, deleteBlock: { [weak self] indexPath in
            let item = items[indexPath.row]
            self?.itemPresenter.deleteItem(item: item)
        }, configurationBlock: { [weak self] cell, item, indexPath in
            cell.binding(item: item)
            cell.editButton.tag = indexPath.row
            cell.editButton.addTarget(self, action: #selector(self?.tappedEditButton(sender:)), for: .touchUpInside)
        })
        tableView.dataSource = dataSource
        refreshControl.endRefreshing()
    }

    @objc private func tappedEditButton(sender: SPRoundedButton) {
        guard let currentItems = items else {
            return
        }
        selectedItem = currentItems[sender.tag]
        performSegue(withIdentifier: Segues.ItemsSegues.showAddItem.rawValue, sender: nil)
    }

    @objc private func getItems() {
        refreshControl.beginRefreshing()
        if let categoryUID = category?.uid {
            itemPresenter.getItems(categoryUID: categoryUID)
        }
    }
}
extension SPItemsViewController: SPItemPresenterProtocol {
    func show(items: [Item]) {
        self.items = items
    }

    func didSuccessAction(_ message: String) {
        getItems()
        showMessage(message)
    }

    func showError(_ message: String) {
        showMessage(message, title: "Error")
    }
}
