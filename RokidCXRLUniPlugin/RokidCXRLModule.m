#import "RokidCXRLModule.h"

@protocol RokidCXRLBridgeProtocol <NSObject>
- (void)bindEventsIfNeeded;
- (void)initializeClient:(NSDictionary *)options completion:(void (^)(NSDictionary *result))completion;
- (NSDictionary *)configureAuth:(NSDictionary *)options;
- (void)authenticate:(NSDictionary *)options completion:(void (^)(NSDictionary *result))completion;
- (void)refreshToken:(NSDictionary *)options completion:(void (^)(NSDictionary *result))completion;
- (NSDictionary *)clearAuthentication;
- (void)watchEvents:(void (^)(NSDictionary *event))handler;
- (NSDictionary *)unwatchEvents;
- (NSDictionary *)setNotifyEventListenCmds:(NSDictionary *)options;
- (void)sendCustomCmd:(NSDictionary *)options completion:(void (^)(NSDictionary *result))completion;
- (void)openCustomView:(NSDictionary *)options completion:(void (^)(NSDictionary *result))completion;
- (void)updateCustomView:(NSDictionary *)options completion:(void (^)(NSDictionary *result))completion;
- (void)closeCustomView:(NSDictionary *)options completion:(void (^)(NSDictionary *result))completion;
- (void)sendCustomViewIcons:(NSDictionary *)options completion:(void (^)(NSDictionary *result))completion;
- (NSDictionary *)startRecord:(NSDictionary *)options;
- (NSDictionary *)stopRecord:(NSDictionary *)options;
- (NSDictionary *)startPlayAudio:(NSDictionary *)options;
- (NSDictionary *)stopPlayAudio;
- (NSDictionary *)feedAudio:(NSDictionary *)options;
- (NSDictionary *)takePhoto;
- (void)takePhotoWithData:(NSDictionary *)options completion:(void (^)(NSDictionary *result))completion;
- (void)queryApp:(void (^)(NSDictionary *result))completion;
- (void)openApp:(NSDictionary *)options completion:(void (^)(NSDictionary *result))completion;
- (void)stopApp:(NSDictionary *)options completion:(void (^)(NSDictionary *result))completion;
- (void)uninstallApp:(NSDictionary *)options completion:(void (^)(NSDictionary *result))completion;
- (void)installApp:(NSDictionary *)options completion:(void (^)(NSDictionary *result))completion;
- (void)changeAudioSceneId:(NSDictionary *)options completion:(void (^)(NSDictionary *result))completion;
- (NSDictionary *)isInitialized;
- (NSDictionary *)isAuthenticated;
- (NSDictionary *)getAuthState;
- (NSDictionary *)getCurrentToken;
- (NSDictionary *)isRokidAppInstalled;
@end

@interface RokidCXRLBridge : NSObject
+ (id<RokidCXRLBridgeProtocol>)sharedInstance;
@end

@implementation RokidCXRLModule

UNI_EXPORT_METHOD(@selector(initialize:callback:))
UNI_EXPORT_METHOD(@selector(configureAuth:callback:))
UNI_EXPORT_METHOD(@selector(authenticate:callback:))
UNI_EXPORT_METHOD(@selector(refreshToken:callback:))
UNI_EXPORT_METHOD(@selector(clearAuthentication:callback:))
UNI_EXPORT_METHOD(@selector(watchEvents:callback:))
UNI_EXPORT_METHOD(@selector(unwatchEvents:callback:))
UNI_EXPORT_METHOD(@selector(setNotifyEventListenCmds:callback:))
UNI_EXPORT_METHOD(@selector(sendCustomCmd:callback:))
UNI_EXPORT_METHOD(@selector(openCustomView:callback:))
UNI_EXPORT_METHOD(@selector(updateCustomView:callback:))
UNI_EXPORT_METHOD(@selector(closeCustomView:callback:))
UNI_EXPORT_METHOD(@selector(sendCustomViewIcons:callback:))
UNI_EXPORT_METHOD(@selector(startRecord:callback:))
UNI_EXPORT_METHOD(@selector(stopRecord:callback:))
UNI_EXPORT_METHOD(@selector(startPlayAudio:callback:))
UNI_EXPORT_METHOD(@selector(stopPlayAudio:callback:))
UNI_EXPORT_METHOD(@selector(feedAudio:callback:))
UNI_EXPORT_METHOD(@selector(takePhoto:callback:))
UNI_EXPORT_METHOD(@selector(takePhotoWithData:callback:))
UNI_EXPORT_METHOD(@selector(queryApp:callback:))
UNI_EXPORT_METHOD(@selector(openApp:callback:))
UNI_EXPORT_METHOD(@selector(stopApp:callback:))
UNI_EXPORT_METHOD(@selector(uninstallApp:callback:))
UNI_EXPORT_METHOD(@selector(installApp:callback:))
UNI_EXPORT_METHOD(@selector(changeAudioSceneId:callback:))

UNI_EXPORT_METHOD_SYNC(@selector(isInitialized:))
UNI_EXPORT_METHOD_SYNC(@selector(isAuthenticated:))
UNI_EXPORT_METHOD_SYNC(@selector(getAuthState:))
UNI_EXPORT_METHOD_SYNC(@selector(getCurrentToken:))
UNI_EXPORT_METHOD_SYNC(@selector(isRokidAppInstalled:))

- (id<RokidCXRLBridgeProtocol>)bridge {
    return [RokidCXRLBridge sharedInstance];
}

- (NSDictionary *)safeOptions:(id)options {
    return [options isKindOfClass:[NSDictionary class]] ? options : @{};
}

- (void)callback:(UniModuleKeepAliveCallback)callback result:(NSDictionary *)result keepAlive:(BOOL)keepAlive {
    if (callback) {
        callback(result, keepAlive);
    }
}

- (void)initialize:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    [[self bridge] initializeClient:[self safeOptions:options] completion:^(NSDictionary *result) {
        [self callback:callback result:result keepAlive:NO];
    }];
}

- (void)configureAuth:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    NSDictionary *result = [[self bridge] configureAuth:[self safeOptions:options]];
    [self callback:callback result:result keepAlive:NO];
}

- (void)authenticate:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    [[self bridge] authenticate:[self safeOptions:options] completion:^(NSDictionary *result) {
        [self callback:callback result:result keepAlive:NO];
    }];
}

- (void)refreshToken:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    [[self bridge] refreshToken:[self safeOptions:options] completion:^(NSDictionary *result) {
        [self callback:callback result:result keepAlive:NO];
    }];
}

- (void)clearAuthentication:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    NSDictionary *result = [[self bridge] clearAuthentication];
    [self callback:callback result:result keepAlive:NO];
}

- (void)watchEvents:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    __weak typeof(self) weakSelf = self;
    [[self bridge] watchEvents:^(NSDictionary *event) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf callback:callback result:event keepAlive:YES];
    }];
    [self callback:callback result:@{@"ok": @YES, @"event": @"watching"} keepAlive:YES];
}

- (void)unwatchEvents:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    NSDictionary *result = [[self bridge] unwatchEvents];
    [self callback:callback result:result keepAlive:NO];
}

- (void)setNotifyEventListenCmds:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    NSDictionary *result = [[self bridge] setNotifyEventListenCmds:[self safeOptions:options]];
    [self callback:callback result:result keepAlive:NO];
}

- (void)sendCustomCmd:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    [[self bridge] sendCustomCmd:[self safeOptions:options] completion:^(NSDictionary *result) {
        [self callback:callback result:result keepAlive:NO];
    }];
}

- (void)openCustomView:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    [[self bridge] openCustomView:[self safeOptions:options] completion:^(NSDictionary *result) {
        [self callback:callback result:result keepAlive:NO];
    }];
}

- (void)updateCustomView:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    [[self bridge] updateCustomView:[self safeOptions:options] completion:^(NSDictionary *result) {
        [self callback:callback result:result keepAlive:NO];
    }];
}

- (void)closeCustomView:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    [[self bridge] closeCustomView:[self safeOptions:options] completion:^(NSDictionary *result) {
        [self callback:callback result:result keepAlive:NO];
    }];
}

- (void)sendCustomViewIcons:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    [[self bridge] sendCustomViewIcons:[self safeOptions:options] completion:^(NSDictionary *result) {
        [self callback:callback result:result keepAlive:NO];
    }];
}

- (void)startRecord:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    NSDictionary *result = [[self bridge] startRecord:[self safeOptions:options]];
    [self callback:callback result:result keepAlive:NO];
}

- (void)stopRecord:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    NSDictionary *result = [[self bridge] stopRecord:[self safeOptions:options]];
    [self callback:callback result:result keepAlive:NO];
}

- (void)startPlayAudio:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    NSDictionary *result = [[self bridge] startPlayAudio:[self safeOptions:options]];
    [self callback:callback result:result keepAlive:NO];
}

- (void)stopPlayAudio:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    NSDictionary *result = [[self bridge] stopPlayAudio];
    [self callback:callback result:result keepAlive:NO];
}

- (void)feedAudio:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    NSDictionary *result = [[self bridge] feedAudio:[self safeOptions:options]];
    [self callback:callback result:result keepAlive:NO];
}

- (void)takePhoto:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    NSDictionary *result = [[self bridge] takePhoto];
    [self callback:callback result:result keepAlive:NO];
}

- (void)takePhotoWithData:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    [[self bridge] takePhotoWithData:[self safeOptions:options] completion:^(NSDictionary *result) {
        [self callback:callback result:result keepAlive:NO];
    }];
}

- (void)queryApp:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    [[self bridge] queryApp:^(NSDictionary *result) {
        [self callback:callback result:result keepAlive:NO];
    }];
}

- (void)openApp:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    [[self bridge] openApp:[self safeOptions:options] completion:^(NSDictionary *result) {
        [self callback:callback result:result keepAlive:NO];
    }];
}

- (void)stopApp:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    [[self bridge] stopApp:[self safeOptions:options] completion:^(NSDictionary *result) {
        [self callback:callback result:result keepAlive:NO];
    }];
}

- (void)uninstallApp:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    [[self bridge] uninstallApp:[self safeOptions:options] completion:^(NSDictionary *result) {
        [self callback:callback result:result keepAlive:NO];
    }];
}

- (void)installApp:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    [[self bridge] installApp:[self safeOptions:options] completion:^(NSDictionary *result) {
        [self callback:callback result:result keepAlive:NO];
    }];
}

- (void)changeAudioSceneId:(NSDictionary *)options callback:(UniModuleKeepAliveCallback)callback {
    [[self bridge] changeAudioSceneId:[self safeOptions:options] completion:^(NSDictionary *result) {
        [self callback:callback result:result keepAlive:NO];
    }];
}

- (NSDictionary *)isInitialized:(NSDictionary *)options {
    return [[self bridge] isInitialized];
}

- (NSDictionary *)isAuthenticated:(NSDictionary *)options {
    return [[self bridge] isAuthenticated];
}

- (NSDictionary *)getAuthState:(NSDictionary *)options {
    return [[self bridge] getAuthState];
}

- (NSDictionary *)getCurrentToken:(NSDictionary *)options {
    return [[self bridge] getCurrentToken];
}

- (NSDictionary *)isRokidAppInstalled:(NSDictionary *)options {
    return [[self bridge] isRokidAppInstalled];
}

@end
