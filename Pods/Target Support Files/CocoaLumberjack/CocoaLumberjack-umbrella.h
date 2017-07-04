#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "CocoaLumberjack.h"
#import "DDAbstractDatabaseLogger.h"
#import "DDASLLogCapture.h"
#import "DDASLLogger.h"
#import "DDAssertMacros.h"
#import "DDFileLogger.h"
#import "DDLegacyMacros.h"
#import "DDLog+LOGV.h"
#import "DDLog.h"
#import "DDLogMacros.h"
#import "DDOSLogger.h"
#import "DDTTYLogger.h"

FOUNDATION_EXPORT double CocoaLumberjackVersionNumber;
FOUNDATION_EXPORT const unsigned char CocoaLumberjackVersionString[];

