/* 
 Boxer is copyright 2011 Alun Bestor and contributors.
 Boxer is released under the GNU General Public License 2.0. A full copy of this license can be
 found in this XCode project at Resources/English.lproj/BoxerHelp/pages/legalese.html, or read
 online at [http://www.gnu.org/licenses/gpl-2.0.txt].
 */


//BXAboutController is a simple window controller which styles and displays the About Boxer panel.

#import <Cocoa/Cocoa.h>

@interface BXAboutController : NSWindowController
{
	IBOutlet NSTextField *version;
}
@property (retain, nonatomic) NSTextField *version;

//Provides a singleton instance of the window controller which stays retained for the lifetime
//of the application. BXAboutController should always be accessed from this singleton.
+ (id) controller;

//Display the credits and acknowledgements help page
- (IBAction) showAcknowledgements: (id)sender;
@end
