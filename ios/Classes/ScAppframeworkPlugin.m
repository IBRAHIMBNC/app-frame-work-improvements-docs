#import "ScAppframeworkPlugin.h"
#if __has_include(<sc_appframework/sc_appframework-Swift.h>)
#import <sc_appframework/sc_appframework-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "sc_appframework-Swift.h"
#endif

@implementation ScAppframeworkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftScAppframeworkPlugin registerWithRegistrar:registrar];
}
@end
