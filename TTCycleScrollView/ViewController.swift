//
//  ViewController.swift
//  TTCycleScrollView
//
//  Created by Wang Shuqing on 16/10/12.
//  Copyright © 2016年 Wang Shuqing. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let imagesURL = ["http://pic38.nipic.com/20140215/12359647_224250202132_2.jpg","http://img.article.pchome.net/00/35/62/34/pic_lib/wm/Zhiwu37.jpg","http://pic106.nipic.com/file/20160812/13948737_155734476000_2.jpg"]
        
        let view2 = TTCycleScrollView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 200), imageNamesGroup: imagesURL)
        
        view2.titlesGroup = ["1", "2", "3"]
        view2.autoScroll = true
        
        view.addSubview(view2)
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

