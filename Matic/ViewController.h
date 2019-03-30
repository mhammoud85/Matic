//
//  ViewController.h
//  Matic
//
//  Created by Mohamad Hammoud on 3/30/19.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

