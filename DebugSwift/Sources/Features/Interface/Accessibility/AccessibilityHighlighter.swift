//
//  AccessibilityHighlighter.swift
//  DebugSwift
//
//  Created by Matheus Gois on 07/03/26.
//

import UIKit

final class AccessibilityHighlighter: @unchecked Sendable {
    static let shared = AccessibilityHighlighter()
    
    private var highlightViews: [UIView] = []
    private var timer: Timer?
    
    private init() {}
    
    func highlight(view: UIView?, duration: TimeInterval = 3.0) {
        guard let view = view else { return }
        
        removeHighlights()
        
        guard let window = view.window else { return }
        
        let frame = view.convert(view.bounds, to: window)
        
        let borderView = UIView(frame: frame)
        borderView.backgroundColor = .clear
        borderView.layer.borderColor = UIColor.systemRed.cgColor
        borderView.layer.borderWidth = 3
        borderView.layer.cornerRadius = 4
        borderView.isUserInteractionEnabled = false
        borderView.alpha = 0
        
        let pulseView = UIView(frame: frame)
        pulseView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
        pulseView.layer.cornerRadius = 4
        pulseView.isUserInteractionEnabled = false
        pulseView.alpha = 0
        
        window.addSubview(pulseView)
        window.addSubview(borderView)
        
        highlightViews.append(contentsOf: [borderView, pulseView])
        
        UIView.animate(withDuration: 0.3) {
            borderView.alpha = 1
            pulseView.alpha = 1
        }
        
        UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat, .autoreverse], animations: {
            pulseView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        })
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.removeHighlights()
        }
    }
    
    func removeHighlights() {
        timer?.invalidate()
        timer = nil
        
        UIView.animate(withDuration: 0.3, animations: {
            self.highlightViews.forEach { $0.alpha = 0 }
        }, completion: { _ in
            self.highlightViews.forEach { $0.removeFromSuperview() }
            self.highlightViews.removeAll()
        })
    }
}
