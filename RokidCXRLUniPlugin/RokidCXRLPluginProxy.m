#import "RokidCXRLPluginProxy.h"

@protocol RokidCXRLBridgeLifecycle <NSObject>
- (void)bindEventsIfNeeded;
- (BOOL)handleOpenURL:(NSURL *)url;
@end

@interface RokidCXRLBridge : NSObject
+ (id<RokidCXRLBridgeLifecycle>)sharedInstance;
@end

@implementation RokidCXRLPluginProxy

- (void)onCreateUniPlugin {
    [[RokidCXRLBridge sharedInstance] bindEventsIfNeeded];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[RokidCXRLBridge sharedInstance] bindEventsIfNeeded];
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [[RokidCXRLBridge sharedInstance] handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    return [[RokidCXRLBridge sharedInstance] handleOpenURL:url];
}

@end
