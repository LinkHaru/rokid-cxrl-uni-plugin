#import <Foundation/Foundation.h>
#import "DCUniDefine.h"

@class DCUniSDKInstance;

@interface DCUniModule : NSObject

@property (nonatomic, strong) dispatch_queue_t uniExecuteQueue;
@property (nonatomic, strong) NSThread *uniExecuteThread;
@property (nonatomic, weak) DCUniSDKInstance *uniInstance;

@end

