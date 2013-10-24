//
//  UTBoxView.h
//  MathGUIdeAid
//
//  Created by Yusuke Iwama on 10/10/13.
//  Copyright (c) 2013 COIINS Project Aid. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UTRadialButtonViewProtocol <NSObject>

- (void)radialButtonActionWithIndex:(NSUInteger)i sender:(id)sender;

@end

@interface UTRadialButtonView : UIView

@property CGFloat x;
@property CGFloat y;
@property CGFloat w;
@property CGFloat h;

@property id delegate;

@property UILabel *label;

@property BOOL selectingMenus;

@property (nonatomic) CGFloat buttonAlpha;

- (id<UTRadialButtonViewProtocol>)initWithFrame:(CGRect)frame titles:(NSArray *)titles delegate:(id)delegate;

- (void)hideMenus;

@end
