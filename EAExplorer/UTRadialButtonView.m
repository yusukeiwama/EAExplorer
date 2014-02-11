//
//  UTBoxView.m
//  MathGUIdeAid
//
//  Created by Yusuke Iwama on 10/10/13.
//  Copyright (c) 2013 COIINS Project Aid. All rights reserved.
//

#import "UTRadialButtonView.h"

#define DURATION 0.4

@implementation UTRadialButtonView {
	NSMutableArray *buttons;
}

@synthesize x, y, w, h;
@synthesize label;
@synthesize selectingMenus;
@synthesize buttonAlpha;
@synthesize delegate;

- (id)initWithFrame:(CGRect)f titles:(NSArray *)t delegate:(id)d
{
    self = [super initWithFrame:f];
    if (self) {
        // Initialization code
		x = f.origin.x;
		y = f.origin.y;
		w = f.size.width;
		h = f.size.height;
		
		delegate = d;
		
		self.layer.cornerRadius = w / 2.0;
		
		label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, w, h)];
		label.textAlignment = NSTextAlignmentCenter;
		label.adjustsFontSizeToFitWidth = YES;
		[self addSubview:label];
		label.text = @"";
		
		// Prepare boxes
		buttons = [NSMutableArray array];
		for (int i = 0; i < [t count]; i++) {
			CGRect rect = CGRectMake(x, y, w, h);
			UIButton *aButton = [UIButton buttonWithType:UIButtonTypeSystem];
			aButton.frame = rect;
			[aButton setTitle:t[i] forState:UIControlStateNormal];
			[aButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
			[aButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
			aButton.titleLabel.font = [UIFont fontWithName:@"Futura" size:32.0];
			double theta = 1.0 / [t count] * i;
			aButton.backgroundColor = [UIColor colorWithHue:theta saturation:1.0 brightness:1.0 alpha:0.9]; //[UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.96]; // lime color
			aButton.layer.cornerRadius = w / 2.0;
			aButton.showsTouchWhenHighlighted = YES;
			aButton.hidden = YES;
			[((UIViewController *)d).view addSubview:aButton];
			[buttons addObject:aButton];
		}
    }
    return self;
}


- (void)buttonAction:(id)sender
{
	int i = (int)[buttons indexOfObject:sender];
	[delegate radialButtonActionWithIndex:i sender:self];
}

- (CGFloat)x { return x; }
- (CGFloat)y { return y; }
- (CGFloat)w { return w; }
- (CGFloat)h { return h; }
- (void)setX:(CGFloat)newX { x = newX, [self updateFrame]; }
- (void)setY:(CGFloat)newY { y = newY, [self updateFrame]; }
- (void)setW:(CGFloat)newW { w = newW, [self updateFrame]; }
- (void)setH:(CGFloat)newH { h = newH, [self updateFrame]; }
- (void)updateFrame { self.frame = CGRectMake(x, y, w, h); }

- (void)setButtonAlpha:(CGFloat)a
{
	buttonAlpha = a;

	for (int i = 0; i < [buttons count]; i++) {
		UIView *aBoxView = buttons[i];
		aBoxView.backgroundColor = [UIColor colorWithRed:0.4 green:0.8 blue:1.0 alpha:buttonAlpha];
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	// Animation
	if (selectingMenus) {
		// hide radial menus
		selectingMenus = NO;
		[UIView animateWithDuration:DURATION animations:^{
			for (int i = 0; i < [buttons count]; i++) {
				UIView *aBoxView = buttons[i];
				CGRect rect = CGRectMake(x, y, w, h);
				aBoxView.frame = rect;
			}
		} completion:^(BOOL finished){
			for (int i = 0; i < [buttons count]; i++) {
				UIView *aBoxView = buttons[i];
				aBoxView.hidden = YES;
			}
		}];
	} else {
		// show radial menus
		[UIView animateWithDuration:DURATION animations:^{
			for (int i = 0; i < [buttons count]; i++) {
				UIView *aBoxView = buttons[i];
				double theta = -2.0 * M_PI / [buttons count] * i - M_PI_2;
				CGRect rect = CGRectMake(x + 1.5 * w * cos(theta),
										 y + 1.5 * w * sin(theta),
										 w, h);
				if (i != 8) aBoxView.frame = rect;
				aBoxView.hidden = NO;
			}
		}];
		selectingMenus = YES;
	}
}

- (void)hideMenus
{
	[self touchesBegan:nil withEvent:nil];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
