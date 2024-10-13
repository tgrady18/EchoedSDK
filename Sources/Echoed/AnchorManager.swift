//
//  AnchorManager.swift
//  Echoed
//
//  Created by Trevor (personal) on 2024-10-12.
//


import Foundation

public class AnchorManager {
    private var hitAnchors: Set<String> = []
    
    public init() {}
    
    public func hitAnchor(_ anchorId: String) {
        hitAnchors.insert(anchorId)
        // In a more advanced version, you might want to log this hit or send it to a server
        print("Anchor hit: \(anchorId)")
    }
    
    public func hasHitAnchor(_ anchorId: String) -> Bool {
        return hitAnchors.contains(anchorId)
    }
    
    public func getAllHitAnchors() -> Set<String> {
        return hitAnchors
    }
    
    public func clearHitAnchors() {
        hitAnchors.removeAll()
    }
}