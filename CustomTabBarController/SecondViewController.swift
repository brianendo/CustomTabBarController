//
//  SecondViewController.swift
//  CustomTabBarController
//
//  Created by Brian Endo on 7/14/17.
//  Copyright © 2017 Brian Endo. All rights reserved.
//

import UIKit

class SecondViewController: ScrollableViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.scrollViewScrolled(scrollView: scrollView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        scrollView.contentInset = UIEdgeInsets(top: inset, left: 0, bottom: 0, right: 0)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.scrollViewScrolled(scrollView: scrollView)
    }
    
}
