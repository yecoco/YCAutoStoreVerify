//
//  AppStoreHeader.h
//  TweakHeader
//
//  Created by yecongcong on 2017/7/17.
//  Copyright © 2017年 lotogram. All rights reserved.
//

#ifndef AppStoreHeader_h
#define AppStoreHeader_h

#import <UIKit/UIKit.h>

@interface SKUIViewController:UIViewController
@end

@interface SKUICardViewElement : NSObject
@property(readonly, retain, nonatomic) NSDictionary *attributes;
@end

@interface SKUIGridViewElementPageSection : NSObject
@end

@interface SKUISearchFieldController : NSObject
@property (nonatomic,readonly) UIViewController * contentsController;
@property (nonatomic,readonly) UISearchBar * searchBar;
-(void)searchBar:(id)arg1 textDidChange:(id)arg2 ;
-(void)searchBarSearchButtonClicked:(id)arg1 ;
@end

@interface SKUIDocumentContainerViewController: SKUIViewController
- (id)childViewController;
@end

@interface SKUIStorePageSectionsViewController:SKUIViewController
@property(readonly, nonatomic) UICollectionView *collectionView;
@property(readonly, nonatomic) NSArray *sections;
-(void)collectionView:(id)arg1 didSelectItemAtIndexPath:(id)arg2 ;
@end

@interface SKUIStackDocumentViewController : SKUIViewController
@property(readonly, nonatomic) SKUIStorePageSectionsViewController *sectionsViewController;
@end

@interface SKUIAccountButtonsViewController:UIViewController
- (void)_signOut;
@end

@interface SKUIAccountButtonsView : UIView
@property(readonly, nonatomic) UIButton *appleIDButton;
@end

@interface SKUITabBarController:UITabBarController
@end

@interface SUViewController : UIViewController
@end

@interface SUWebView : UIWebView
@end

@interface SUWebViewController : SUViewController
@property(readonly, nonatomic) SUWebView *webView;
- (BOOL)bSuccessDoNext;
- (void)findWebError;
@end

@interface SKUIOfferView : UIView
-(void)_buttonAction:(id)arg1 ;
@property (nonatomic,retain) NSMutableArray * offerButtonViews;
@end

@interface SKUIItemOfferButton : UIControl
@property (assign,nonatomic) id delegate;
@end

#endif /* AppStoreHeader_h */
