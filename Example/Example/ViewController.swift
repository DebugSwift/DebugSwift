//
//  ViewController.swift
//  Example
//
//  Created by Matheus Gois on 16/12/23.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        LocationManager.shared.didUpdate = { [weak self] value in
            self?.text.text = value
        }
    }

    @IBOutlet var text: UILabel!

    @IBAction func successMocked() {
        let random: Int = .random(in: 1...5)
        let url = "https://reqres.in/api/users?page=\(random)"
        RequestManager.mockRequest(url: url)
    }

    @IBAction func failureRequest() {
        let url = "https://reqres.in/api/users/23"
        RequestManager.mockRequest(url: url)
    }

    @IBAction func seeLocation() {
        LocationManager.shared.requestLocation()
    }

    @IBAction func crash() {
        // Signal
//        var index: Int?
//        print(index!)

        // Exception
        let array = NSArray()
        let element = array.object(at: 4)

        DispatchQueue.global().async {
            // Exception
//            let array = NSArray()
//            let element = array.object(at: 4)
        }
    }
}

extension Thread {
    var threadName: String {
        if isMainThread {
            return "main"
        } else if let threadName = Thread.current.name, !threadName.isEmpty {
            return threadName
        } else {
            return description
        }
    }

    var queueName: String {
        if let queueName = String(validatingUTF8: __dispatch_queue_get_label(nil)) {
            return queueName
        } else if let operationQueueName = OperationQueue.current?.name, !operationQueueName.isEmpty {
            return operationQueueName
        } else if let dispatchQueueName = OperationQueue.current?.underlyingQueue?.label, !dispatchQueueName.isEmpty {
            return dispatchQueueName
        } else {
            return "n/a"
        }
    }
}
