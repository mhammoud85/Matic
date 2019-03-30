//
//  ViewController.m
//  Matic
//
//  Created by Mohamad Hammoud on 3/30/19.
//

#import "ViewController.h"

@implementation ViewController
{
    NSMutableArray *array;
    BOOL lastItemReached;
    BOOL hasMore;
    int page;
}

- (void)viewDidLoad
{
    self.navigationItem.title = @"Trending Repos";
    
    array = [[NSMutableArray alloc]init];
    hasMore = YES;
    
    CGRect frame = CGRectZero;
    frame.size.height = CGFLOAT_MIN;
    self.tableView.tableHeaderView = [[UIView alloc]initWithFrame:frame];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self githubAPI];
}

#pragma mark - Table View
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    
    for(UIImageView *imageView in cell.contentView.subviews)
    {
        [imageView removeFromSuperview];
    }
    
    for(UILabel *label in cell.contentView.subviews)
    {
        [label removeFromSuperview];
    }
    
    NSDictionary *dic = [array objectAtIndex:indexPath.row];
    NSDictionary *owner = [dic valueForKey:@"owner"];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 4, tableView.frame.size.width-8, 20)];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:15]];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    [cell.contentView addSubview:titleLabel];
    
    UILabel *detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, titleLabel.frame.origin.y+titleLabel.frame.size.height, tableView.frame.size.width-8, 40)];
    [detailLabel setFont:[UIFont systemFontOfSize:14]];
    detailLabel.textAlignment = NSTextAlignmentLeft;
    detailLabel.lineBreakMode = NSLineBreakByWordWrapping;
    detailLabel.numberOfLines = 0;
    [cell.contentView addSubview:detailLabel];
    
    UIImageView *photoImg = [[UIImageView alloc] initWithFrame:CGRectMake(8, detailLabel.frame.origin.y+detailLabel.frame.size.height, 24, 24)];
    [cell.contentView addSubview:photoImg];

    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(photoImg.frame.origin.x+photoImg.frame.size.width+4, detailLabel.frame.origin.y+detailLabel.frame.size.height, 2*tableView.frame.size.width/3-(photoImg.frame.origin.x+photoImg.frame.size.width)-2*4, 20)];
    [nameLabel setFont:[UIFont systemFontOfSize:13]];
    nameLabel.textAlignment = NSTextAlignmentLeft;
    [cell.contentView addSubview:nameLabel];
    
    UILabel *starLabel = [[UILabel alloc] initWithFrame:CGRectMake(2*tableView.frame.size.width/3, detailLabel.frame.origin.y+detailLabel.frame.size.height, tableView.frame.size.width/3-8, 20)];
    [starLabel setFont:[UIFont boldSystemFontOfSize:13]];
    starLabel.textAlignment = NSTextAlignmentRight;
    [cell.contentView addSubview:starLabel];
    
    if([dic valueForKey:@"name"])
        titleLabel.text = [dic valueForKey:@"name"];
    if([dic valueForKey:@"description"] && ![[dic valueForKey:@"description"] isKindOfClass:[NSNull class]])
        detailLabel.text = [dic valueForKey:@"description"];
    if([owner valueForKey:@"login"])
        nameLabel.text = [owner valueForKey:@"login"];
    if([dic valueForKey:@"stargazers_count"])
    {
        int stargazers_count = [[dic valueForKey:@"stargazers_count"]intValue];
        if(stargazers_count > 999999)
        {
            float x = stargazers_count/1000000.0;
            starLabel.text = [NSString stringWithFormat:@"★ %.1fm",x];
            
        }
        else if(stargazers_count > 999)
        {
            float x = stargazers_count/1000.0;
            starLabel.text = [NSString stringWithFormat:@"★ %.1fk",x];
            
        }
        else
            starLabel.text = [NSString stringWithFormat:@"★ %d",[[dic valueForKey:@"stargazers_count"]intValue]];
    }
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *photoKey = [owner valueForKey:@"avatar_url"];
    NSString *lastPathComponent = [photoKey lastPathComponent];
    if(photoKey && ![photoKey isEqualToString:@""])
    {
        NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"profile_small/%@",lastPathComponent]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath])
        {
            photoImg.image = [UIImage imageWithContentsOfFile:imagePath];
        }
        else
        {
            NSURL *storeURL = [NSURL URLWithString:photoKey];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSData *imageData = [NSData dataWithContentsOfURL:storeURL];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError *error;
                    NSString *folderPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"profile_small"]];
                    if (![[NSFileManager defaultManager] fileExistsAtPath:folderPath])
                    {
                        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:NO attributes:nil error:nil];
                    }
                    if([imageData writeToFile:imagePath options:NSDataWritingAtomic error:&error])
                    {
                        photoImg.image = [UIImage imageWithData:imageData];
                    }
                });
            });
        }
    }
    
    if(!lastItemReached && indexPath.row == [array count]-1 && hasMore)
    {
        lastItemReached = YES;
        [self githubAPI];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90;
}

-(void)githubAPI
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *now = [NSDate date];
    NSDate *monthAgo = [now dateByAddingTimeInterval:-30*24*60*60];
    NSString *dateStr = [formatter stringFromDate:monthAgo];
    NSString *strURL = [NSString stringWithFormat:@"https://api.github.com/search/repositories?q=created:<%@&sort=stars&order=desc",dateStr];
    if(page > 0)
        strURL = [NSString stringWithFormat:@"%@&page=%d",strURL,page];
    strURL = [strURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    [request setURL:[NSURL URLWithString:strURL]];
    [request setHTTPMethod:@"GET"];
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
      {
          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
          if(httpResponse.statusCode == 422)
          {
              hasMore = NO;
          }
          else if(!error)
          {
              NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
              lastItemReached = NO;
              hasMore = YES;
              page = page+1;
              if([array count] == 0)
              {
                  array = [[dictionary valueForKey:@"items"]mutableCopy];
              }
              else
              {
                  NSArray *tmp = [dictionary valueForKey:@"items"];
                  [array addObjectsFromArray:tmp];
              }
              dispatch_async(dispatch_get_main_queue(), ^{
                  [self.tableView reloadData];
              });
          }
      }] resume];
}

@end
