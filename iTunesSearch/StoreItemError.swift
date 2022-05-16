//
//  StoreItemError.swift
//  iTunesSearch
//
//  Created by Daria Salamakha on 11.05.2022.
//

import Foundation

enum StoreItemError: Error, LocalizedError {
    case itemsNotFound
    case imageNotFound
}
